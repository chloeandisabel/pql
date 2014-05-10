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
end


module PQL

  # root class for nodes
  
  class Node < Treetop::Runtime::SyntaxNode
  end


  # block

  class Block < Node

    # return the single match from the first statement in the block
    def match(stream)
      expression = descendants_to(MatchingExpression).first

      if expression
        expression.match stream
      else
        nil
      end
    end

    # return all matches in the block
    def matches(stream)
      descendants_to(MatchingExpression).map{|e| e.match stream}
    end

    # return all named matches as a hash
    def named_matches(stream)
      descendants_to(MatchingExpression)
        .select{|e| e.respond_to? :name}
        .reduce({}){|memo, e|
          memo[e.name.value] = e.match stream
          memo
        }
    end

  end

  # expressions and clauses

  class MatchingExpression < Node
    def match(stream)
      selective_expression.select stream
    end

    def name
      descendants_to(Name, SelectiveExpression).find{|e| e.is_a? Name}
    end
  end

  class SelectiveExpression < Node
    def select(stream)
      matches = stream.select &condition.to_proc(stream)
      matches = subset_operator.operate matches if respond_to? :subset_operator
      matches
    end
  end

  class ValueExpression < Node
    def value(stream)
      value = selective_expression.select(stream).map{|obj| obj[:"#{name.value}"]}
      value = reductive_operator.operate value if respond_to? :reductive_operator
      value
    end
  end

  class Condition < Node
    def to_proc(stream)
      # memoize proc for a given stream
      return @proc if @proc and @stream == stream
      @stream = stream

      # return a proc taking an object and returning a boolean indicating whether
      # or not that object meets the condition
      @proc = -> (obj) do
        nodes = descendants_to Condition, Comparison, LogicalOperator

        left_value = nodes.shift.to_proc(stream).call obj

        while nodes.length > 1
          operator, right = nodes[0..1]
          nodes = nodes[2..-1]

          right_value = right.to_proc(stream).call obj

          left_value = operator.operate left_value, right_value
        end
        
        left_value
      end
    end
  end

  class Comparison < Node
    def to_proc(stream)
      # memoize proc for a given stream
      return @proc if @proc and @stream == stream
      @stream = stream

      left_value = left.value
      right_value = (right.is_a?(Literal) || right.is_a?(Name)) ? right.value : right.value(stream)

      # return a proc taking an object and comparing it to a literal value.
      @proc = -> (obj) do
        comparative_operator.operate obj[left_value], right_value
      end
    end
  end


  # subset operators

  class SubsetOperator < Node
    def operate(stream)
      child.operate stream
    end
  end

  class FirstByOperator < SubsetOperator
    def operate(stream)
      quantity = (respond_to? :integer_literal) ? integer_literal.value : 1
      stream.sort_by{|obj| obj[name.value]}[0, quantity]
    end
  end

  class LastByOperator < SubsetOperator
    def operate(stream)
      quantity = (respond_to? :integer_literal) ? integer_literal.value : 1
      stream.sort_by{|obj| obj[name.value]}.reverse[0, quantity]
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
      values.max
    end
  end

  class MinOperator < ReductiveOperator
    def operate(values)
      values.min
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
      left >= right
    end
  end

  class IsLessThanOrEqualToOperator < ComparativeOperator
    def operate(left, right)
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

  class IsGreaterThanOperator < ComparativeOperator
    def operate(left, right)
      left > right
    end
  end

  class IsLessThanOperator < ComparativeOperator
    def operate(left, right)
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

  class NullLiteral < Literal
    def value
      nil
    end
  end


  # name helpers

  class Name < Node
    def value
      text_value.strip.to_sym
    end
  end

end
