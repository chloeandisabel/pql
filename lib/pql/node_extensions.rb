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


  # class representing set of matches between a block of expressions and a stream of events

  class MatchSet

    # accepts
    def initialize(expression_results)
      @expression_results = expression_results
    end

    attr_reader :expression_results

    # any matching expressions from the block that fail to match will have returned nil.
    # return true if all expressions have matched, false otherwise
    def matches?
      @expression_results.all?{|result| result[:matches]}
    end

    # the cardinality is the length of the cartesian product of all match sets
    def cardinality
      return 0 unless matches?

      @expression_results.reduce(1){|memo, result|
        result[:matches].any? ? memo * result[:matches].length : memo
      }
    end

    # return flat array of all matching events
    def all_matches
      return [] unless matches?
      @expression_results.reduce([]){|memo, result| memo + result[:matches]}.flatten
    end


    # convert sets of expression matches to arrays of hashes {name: [events..]},
    # find the cartesian product of each expression's set of distinct matches, and merge
    # hashes to produce complete sets of named matches
    def named_matches
      return [] unless matches?

      head, *tail = @expression_results.map{|result|
        if result[:matches].any?
          result[:matches].map{|match|
            result[:name] ? Hash[result[:name], match] : {}
          }.compact
        else
          [{}]
        end
      }

      head.product(*tail).map{|matches| 
        matches.reduce(&:merge)
      }
    end

    def each_match(&block)
      named_matches.map{|match| block.call match}
    end
  end



  # block

  class Block < Node

    # apply the block to a stream
    def apply(stream)
      MatchSet.new descendants_to(MatchingExpression).map{|expression|
        {name: expression.match_name, matches: expression.match(stream)}
      }
    end

  end


  # expressions and clauses

  class MatchingExpression < Node
    def match(stream)
      matches = filtering_expression.apply(stream, [])
      matches = selective_expression.apply matches if respond_to? :selective_expression
      matches
    end

    def match_name
      respond_to?(:name) ? name.value : nil
    end
  end

  class ValueExpression < Node
    def value(stream, context)
      events = filtering_expression.apply(stream, context)
      events = subset_expression.apply events if respond_to? :subset_expression
      value = events.map{|event| event[:"#{name.value}"]}
      value = reductive_operator.operate value if respond_to? :reductive_operator
      value
    end
  end

  class FilteringExpression < Node
    def apply(stream, context)
      stream.select &condition.to_proc(stream, context)
    end
  end


  # conditions

  class Condition < Node
    def to_proc(stream, context)
      # return a proc taking an event and returning a boolean indicating whether
      # or not that event meets the condition

      -> (event) do
        nodes = descendants_to Condition, AtomicCondition, LogicalOperator
        event_context = [event] + context

        left_value = nodes.shift.compare stream, event_context

        while nodes.length > 1
          operator, right = nodes[0..1]
          nodes = nodes[2..-1]

          return false if left_value == false and operator.is_a?(AndOperator)

          right_value = right.compare stream, event_context

          left_value = operator.operate left_value, right_value
        end

        left_value
      end
    end
  end

  class AtomicCondition < Node
    def compare(stream, context)
      child.compare stream, context
    end
  end

  class TypicalCondition < AtomicCondition
    def compare(stream, context)
    end
  end

  class ComparativeCondition < AtomicCondition
    def compare(stream, context)
      left_value, right_value = [left, right].map do |node|
        if node.is_a? Literal
          node.value
        elsif node.is_a? ValueExpression
          node.value(stream, context)
        elsif node.is_a? Reference
          context[node.index][node.value]
        end
      end

      comparative_operator.operate left_value, right_value
    end
  end


  # selective and subset expressions

  class SelectiveExpression < Node
    def apply(stream)
      nodes = descendants_to LimitingExpression, OrderingExpression, CardinalityExpression
      matches = [stream]

      nodes.reverse.reduce(matches) do |matches, node|
        node.apply(matches)
      end
    end
  end

  class SubsetExpression < Node
    def apply(stream)
      nodes = descendants_to LimitingExpression, OrderingExpression
      nodes.reverse.reduce(stream){|memo,node| node.apply(stream)}
    end
  end


  # limiting expressions

  class LimitingExpression < Node
    def apply(matches)
      matches.map{|match| child.operate match}
    end
  end

  class FirstOperator < Node
    def operate(stream)
      quantity = (respond_to? :integer_literal) ? integer_literal.value : 1
      stream[0, quantity]
    end
  end

  class LastOperator < Node
    def operate(stream)
      quantity = (respond_to? :integer_literal) ? integer_literal.value : 1
      stream.reverse[0, quantity]
    end
  end


  # ordering expression

  class OrderingExpression < Node
    def apply(matches)
      matches.map do |match|
        result = match.sort_by{|event| event[name.value]}
        result.reverse! if descending.text_value.length > 0
        result
      end
    end
  end


  # cardinality expressions

  class CardinalityExpression < Node
    def apply(matches)
      matches.reduce([]) do |memo, match|
        (memo && result = child.operate(match)) ? memo + result : nil
      end
    end
  end

  class NoneOperator < Node
    def operate(stream)
      stream.none? ? [] : nil
    end
  end

  class EachOperator < Node
    def operate(stream)
      stream.zip
    end
  end

  class AllOperator < Node
    def operate(stream)
      stream.any? ? [stream] : nil
    end
  end

  class AnyOperator < Node
    def operate(stream)
      stream.any? ? [stream] : []
    end
  end

  class GroupedByOperator < Node
    def operate(stream)
      stream.group_by{|event| event[:"#{name.value}"]}.values
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

    def index
      escapes.text_value.length
    end
  end

  class Name < Node
    def value
      text_value.strip.to_sym
    end
  end

end
