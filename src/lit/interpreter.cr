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

      runtime_error(expr.operator, "Unknown unary operator. This is probably a parsing error. My bad =(")
    end

    def visit_binary_expr(expr) : Obj
      left = evaluate(expr.left)
      right = evaluate(expr.right)

      case expr.operator.type
      when .plus?
        if left.is_a? Float64 && right.is_a? Float64
          return left.as(Float64) + right.as(Float64)
        end

        if left.is_a? String && right.is_a? String
          return left.to_s + right.to_s
        end

        runtime_error(expr.operator, "Operands must be two numbers or two strings.")
      when .minus?
        check_number_operands(expr.operator, left, right)

        return left.as(Float64) - right.as(Float64)
      when .star?
        check_number_operands(expr.operator, left, right)

        return left.as(Float64) * right.as(Float64)
      when .slash?
        check_number_operands(expr.operator, left, right)

        return left.as(Float64) / right.as(Float64)
      end

      runtime_error(expr.operator, "Unknown binary operator. This is probably a parsing error. My bad =(")
    end

    def visit_grouping_expr(expr) : Obj
      evaluate(expr.expression)
    end

    def evaluate(expr) : Obj
      expr.accept(self)
    end

    private def check_number_operand(operator, operand : Obj)
      return if operand.is_a? Float64

      runtime_error(operator, "Operand must be a number.")
    end

    private def check_number_operands(operator, left : Obj, right : Obj)
      return if left.is_a? Float64 && right.is_a? Float64

      runtime_error(operator, "Operands must be numbers.")
    end

    private def truthy?(obj : Obj) : Bool
      !!obj
    end

    private def runtime_error(token, msg)
      raise RuntimeError.new(token, msg)
    end
  end
end
