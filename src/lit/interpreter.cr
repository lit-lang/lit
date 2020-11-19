require "./expr"
require "./obj"

module Lit
  class Interpreter
    include Expr::Visitor

    def initialize(@exprs : Array(Expr)); end

    def self.interpret(exprs)
      new(exprs).interpret
    end

    def interpret
      @exprs.each { |expr| evaluate(expr) }
    end

    def visit_literal_expr(expr) : Obj
      expr.value
    end

    def visit_unary_expr(expr) : Obj
      right = evaluate(expr.right)

      case expr.operator.type
      when .minus?
        return -right.as(Float64)
      when .bang?
        return !truthy?(right)
      end

      # raise
      nil
    end

    def visit_binary_expr(expr) : Obj
      1.0
    end

    def visit_grouping_expr(expr) : Obj
      1.0
    end

    def evaluate(expr) : Obj
      expr.accept(self)
    end

    private def truthy?(obj : Obj) : Bool
      !!obj
    end
  end
end
