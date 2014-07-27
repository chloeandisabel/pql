require 'treetop'

class Treetop::Runtime::SyntaxNode
  def syntax_node?
    self.class.name == 'Treetop::Runtime::SyntaxNode'
  end

  # return an array of all descendants of the node
  def descendants
    if elements
      elements.map{|e| [e] + e.descendants}.flatten
    else
      []
    end
  end

  # return an array of all descendants of the node terminating at the given node types
  # depth first in left to right order
  def descendants_to(*node_types)
    elements.map{|e|
      if node_types.include? e.class
        e
      elsif e.elements
        e.descendants_to *node_types
      else
        []
      end
    }.flatten
  end

  # print 
  def display(level=0)
    puts self.class.name
    
    elements and elements.each do |e|
      level.times do
        print '  '
      end

      e.display(level + 1)
    end
  end
end



module PQL

  # root class for nodes

  class Node < Treetop::Runtime::SyntaxNode
  end


  # block

  class Block < Node

    # apply the block to a set of events
    def apply(events)
      expression_applications = descendants_to(MatchingExpression).reduce([]) do |precedents, expression|
        expression_application = expression.match events, precedents

        if expression.name and precedents.any?{|precedent| precedent.name == expression.name}
          raise 'match names within a block must be unique'
        end

        precedents << expression_application
      end

      BlockApplication.new expression_applications
    end

  end


  # expressions and clauses

  class MatchingExpression < Node
    def match(events, precedents)
      filtered_events = filtering_expression.apply events, []
      
      matches = [Match.new(filtered_events)]
      matches = selective_expression.apply matches
      matches = joining_expression.apply matches, precedents if respond_to? :joining_expression

      MatchingExpressionApplication.new matches, name, respond_to?(:joining_expression)
    end

    def name
      naming_expressions = descendants_to NamingExpression
      naming_expressions.any? ? naming_expressions.first.value : nil
    end
  end

  class NamingExpression < Node
    def value
      name.value
    end
  end

  class ValueExpression < Node
    def value(events, context)
      filtered_events = filtering_expression.apply events, context
      
      # we need to covert to matches to apply a subset expression,
      # we convert back after application
      if respond_to? :subset_expression
        matches = filtered_events.map {|event| Match.new [event]}
        matches = subset_expression.apply matches
        filtered_events = matches.map{|match| match.events.first}
      end

      value = filtered_events.map{|event| event[:"#{name.value}"]}
      value = reductive_operator.operate value if respond_to? :reductive_operator
      value
    end
  end

  class FilteringExpression < Node
    def apply(events, context, subject = nil)
      events.select &condition.to_proc(events, context, subject)
    end
  end

  class JoiningExpression < Node
    def apply(matches, precedents)
      subject_expression = precedents.find{|application| application.name == name.value}
      raise "cannot perform join, expression named `#{name.value}` not found" unless subject_expression

      matches = subject_expression.matches.reduce([]) do |memo, left_match|
        memo + matches.reduce([]) do |memo, right_match|

          if right_match.events.empty?
          
            memo << Match.new([], right_match.singular, left_match)
          
          else
          
            filtered_events = right_match.events.select do |right_event|
              left_match.events.any? do |left_event|
                condition.to_proc([], [], left_event).call(right_event)
              end
            end

            unless filtered_events.empty?
              memo << Match.new(filtered_events, right_match.singular, left_match)
            end
          
          end

          memo
        end
      end
    end

    def condition
      filtering_expression.condition
    end
  end


  # conditions

  class Condition < Node
    def to_proc(events, context, subject)
      # return a proc taking an event and returning a boolean indicating whether
      # or not that event meets the condition

      -> (event) do
        nodes = descendants_to Condition, AtomicCondition, LogicalOperator
        event_context = [event] + context

        left_value = nodes.shift.compare events, event_context, subject

        while nodes.length > 1
          operator, right = nodes[0..1]
          nodes = nodes[2..-1]

          return false if left_value == false and operator.is_a?(AndOperator)

          right_value = right.compare events, event_context, subject

          left_value = operator.operate left_value, right_value
        end

        left_value
      end
    end
  end

  class AtomicCondition < Node
    def compare(events, context, subject)
      child.compare events, context, subject
    end
  end

  class TypicalCondition < AtomicCondition
    def compare(events, context, subject)
    end
  end

  class ComparativeCondition < AtomicCondition
    def compare(events, context, subject)
      left_value, right_value = [left, right].map do |node|
        if node.is_a? Literal
          node.value
        elsif node.is_a? ValueExpression
          node.value(events, context)
        elsif node.is_a? Reference
          if subject and node.subject
            subject[node.value]
          else
            context[node.index][node.value]
          end
        end
      end

      comparative_operator.operate left_value, right_value
    end
  end


  # selective and subset expressions

  class SelectiveExpression < Node
    def apply(matches)
      nodes = descendants_to LimitingExpression, OrderingExpression, CardinalityExpression

      nodes.reverse.reduce matches do |matches, node|
        node.apply matches
      end
    end
  end

  class SubsetExpression < Node
    def apply(matches)
      nodes = descendants_to LimitingExpression, OrderingExpression
      
      nodes.reverse.reduce matches do |matches, node|
        node.apply matches
      end
    end
  end


  # limiting expressions

  class LimitingExpression < Node
    def apply(matches)
      matches.map do |match|
        child.operate match
      end
    end
  end

  class FirstOperator < Node
    def operate(match)
      quantity = (respond_to? :integer_literal) ? integer_literal.value : 1
      match.singular = true if quantity == 1
      match.events = match.events[0, quantity]
      match
    end
  end

  class LastOperator < Node
    def operate(match)
      quantity = (respond_to? :integer_literal) ? integer_literal.value : 1
      match.singular = true if quantity == 1
      match.events = match.events.reverse[0, quantity]
      match
    end
  end


  # ordering expression

  class OrderingExpression < Node
    def apply(matches)
      matches.map do |match|
        match.events = match.events.sort_by{|event| event[name.value]}
        match.events.reverse! if descending.text_value.length > 0
        match
      end
    end
  end


  # cardinality expressions

  class CardinalityExpression < Node
    def apply(matches)
      matches.reduce [] do |memo, match|
        (memo && result = child.operate(match)) ? memo + result : nil
      end
    end
  end

  class AllOperator < Node
    def operate(match)
      match.events.any? ? [match] : nil
    end
  end

  class NoneOperator < Node
    def operate(match)
      match.events.none? ? [match] : nil
    end
  end

  class AnyOperator < Node
    def operate(match)
      [match]
    end
  end

  class EachOperator < Node
    def operate(match)
      match.events.map do |event|
        Match.new [event], true, match.join
      end
    end
  end

  class GroupedByOperator < Node
    def operate(match)
      grouped = match.events.group_by{|event| event[:"#{name.value}"]}.values
      grouped.map do |events|
        Match.new events
      end
    end
  end



  # reductive operators

  class ReductiveOperator < Node
    def operate(values)
      child.operate values
    end
  end

  class MaxOperator < ReductiveOperator
    def operate(values)
      values.any? ? values.max : -Float::INFINITY
    end
  end

  class MinOperator < ReductiveOperator
    def operate(values)
      values.any? ? values.min : Float::INFINITY
    end
  end

  class CountOperator < ReductiveOperator
    def operate(values)
      values.length
    end
  end

  class SumOperator < ReductiveOperator
    def operate(values)
      values.reduce(0){|sum, value| sum + value}
    end
  end

  class UnionOperator < ReductiveOperator
    def operate(values)
      values.reduce([]){|union, value| union | value}
    end
  end


  # logical operators

  class LogicalOperator < Node
    def operate(left, right)
      child.operate left, right
    end
  end

  class AndOperator < LogicalOperator
    def operate(left, right)
      left && right
    end
  end

  class OrOperator < LogicalOperator
    def operate(left, right)
      left || right
    end
  end


  # comparative operators

  class ComparativeOperator < Node
    def operate(left, right)
      child.operate left, right
    end
  end

  class DoesNotEqualOperator < ComparativeOperator
    def operate(left, right)
      left != right
    end
  end

  class IsGreaterThanOrEqualToOperator < ComparativeOperator
    def operate(left, right)
      return false unless left.respond_to? :>=
      left >= right
    end
  end

  class IsLessThanOrEqualToOperator < ComparativeOperator
    def operate(left, right)
      return false unless left.respond_to? :<=
      left <= right
    end
  end

  class MatchesOperator < ComparativeOperator
    def operate(left, right)
      left =~ right
    end
  end

  class IsInOperator < ComparativeOperator
    def operate(left, right)
      right.include? left
    end
  end

  class IsNotInOperator < ComparativeOperator
    def operate(left, right)
      !right.include? left
    end
  end

  class IncludesOperator < ComparativeOperator
    def operate(left, right)
      left.include? right
    end
  end

  class DoesNotIncludeOperator < ComparativeOperator
    def operate(left, right)
      !left.include? right
    end
  end

  class IntersectsOperator < ComparativeOperator
    def operate(left, right)
      (left & right).any?
    end
  end

  class DisjointOperator < ComparativeOperator
    def operate(left, right)
      (left & right).none?
    end
  end

  class IsGreaterThanOperator < ComparativeOperator
    def operate(left, right)
      return false unless left.respond_to? :>
      left > right
    end
  end

  class IsLessThanOperator < ComparativeOperator
    def operate(left, right)
      return false unless left.respond_to? :<
      left < right
    end
  end

  class EqualsOperator < ComparativeOperator
    def operate(left, right)
      left == right
    end
  end


  # literals

  class Literal < Node
    def value
      child.value
    end
  end

  class ListLiteral < Literal
    def value
      # prune syntax nodes from tree
      descendants_to(Literal).map{|e| e.value}
    end
  end

  class StringLiteral < Literal
    def value
      text_value[1...-1]
    end
  end

  class RegularExpressionLiteral < Literal
    def value
      Regexp.new text_value[1...-1]
    end
  end

  class FloatLiteral < Literal
    def value
      text_value.to_f
    end
  end

  class IntegerLiteral < Literal
    def value
      text_value.to_i
    end
  end

  class NowLiteral < Literal
    def value
      Time.now
    end
  end

  class TimeDeltaLiteral < Literal
    def value

    end
  end

  class NullLiteral < Literal
    def value
      nil
    end
  end


  # name and reference

  class Reference < Node
    def value
      name.value
    end

    def subject
      name.subject
    end

    def index
      escapes.text_value.length
    end
  end

  class Name < Node
    def value
      text_value.strip.split('.').last.to_sym
    end

    def subject
      parts = text_value.strip.split '.'

      if parts.length == 2
        parts[0].to_sym
      else
        nil
      end
    end
  end

end
