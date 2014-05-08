class Treetop::Runtime::SyntaxNode
  def syntax_node?
    self.class.name == 'Treetop::Runtime::SyntaxNode'
  end

  def get(node_type)
    elements.find{|e| e.is_a? node_type}
  end

  def all(node_type)
    elements.select{|e| e.is_a? node_type}
  end
end


module PatternDescription

  # expressions and clauses

  class MatchingExpression < Treetop::Runtime::SyntaxNode
    def matches(stream)
      stream.select &get(Condition).to_proc
    end
  end

  class ValueExpression < Treetop::Runtime::SyntaxNode
    def values(stream)
      values = matching_expression.matches.map &:"#{name.value}"
      values = reductive_operator.operate values if reductive_operator
      values
    end
  end

  class Condition < Treetop::Runtime::SyntaxNode
    def compound?
      logical_operator.present?
    end

    def match

    end

    def compound_match
    end

    def to_proc
      if logical_operator
        logical_operator
      else
        -> (subject) {comparative_operator.operate subject.send(left), right}
      end
    end
  end

  class OrderedCondition < Condition
    def left
      condition.left
    end

    def right
      condition.right
    end

    def subcondition
    end
  end

  class UnorderedCondition < Condition
    def left
      name.value
    end

    def right
      if literal
        literal.value
      else
        value_expression
      end
    end

    def subcondition
      condition
    end
  end


  # reductive operators

  class ReductiveOperator < Treetop::Runtime::SyntaxNode
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

  class LogicalOperator < Treetop::Runtime::SyntaxNode
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

  class ComparativeOperator < Treetop::Runtime::SyntaxNode
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

  class EqualsOperator < PatternDescription::ComparativeOperator
    def operate(left, right)
      left == right
    end
  end


  # literals

  class Literal < Treetop::Runtime::SyntaxNode
  end

  class ListLiteral < Literal
    def value
      elements.map{|e| e.value}
    end
  end

  class StringLiteral < Literal
    def value
      text_value[1..-2]
    end
  end

  class RegularExpressionLiteral < Literal
    def value
      Regexp.new text_value[1..-2]
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

  class Name < Treetop::Runtime::SyntaxNode
  end

end
