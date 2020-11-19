require "./lit"
require "./expr"
require "./obj"
require "./runtime_error"

module Lit
  class Interpreter
    include Expr::Visitor

    def initialize(@exprs : Array(Expr)); end

    def self.interpret(exprs)
      new(exprs).interpret
    end

    def interpret
      @exprs.each { |expr| pp evaluate(expr) }
    rescue e : RuntimeError
      Lit.runtime_error(e)
    end

    def visit_literal_expr(expr) : Obj
      expr.value
    end

    def visit_unary_expr(expr) : Obj
      right = evaluate(expr.right)

      case expr.operator.type
      when .minus?
        check_number_operand(expr.operator, right)

        return -right.as(Float64)
      when .bang?
        return !truthy?(right)
      end

      raise RuntimeError.new(expr.operator, "Unknown unary operator. This is probably a parsing error. My bad =(")
    end

    def visit_binary_expr(expr) : Obj
      "binary_expr"
    end

    def visit_grouping_expr(expr) : Obj
      evaluate(expr.expression)
    end

    def evaluate(expr) : Obj
      expr.accept(self)
    end

    private def check_number_operand(operator, operand : Obj)
      return if operand.is_a? Float64

      raise RuntimeError.new(operator, "Operand must be a number.")
    end

    private def truthy?(obj : Obj) : Bool
      !!obj
    end
  end
end
