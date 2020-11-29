require "./lit"
require "./expr"
require "./stmt"
require "./obj"
require "./runtime_error"
require "./environment"

module Lit
  class Interpreter
    include Expr::Visitor
    include Stmt::Visitor

    # TODO: Exclude this after e2e tests
    getter environment
    @environment = Environment.new

    def self.interpret(stmts : Array(Stmt))
      new.interpret(stmts)
    end

    def interpret(stmts) : Nil
      stmts.each { |stmt| execute(stmt) }
    rescue e : RuntimeError
      Lit.runtime_error(e)
    end

    def visit_print_stmt(stmt) : Nil
      puts stringify(evaluate(stmt.expression))
    end

    def visit_let_stmt(stmt) : Nil
      @environment.define(stmt.name.lexeme, evaluate(stmt.initializer))
    end

    def visit_expression_stmt(stmt) : Nil
      evaluate(stmt.expression)
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
        return falsey?(right)
      end

      runtime_error(expr.operator, "Unknown unary operator. This is probably a parsing error. My bad =(")
    end

    def visit_binary_expr(expr) : Obj
      left = evaluate(expr.left)
      right = evaluate(expr.right)

      case expr.operator.type
      when .greater?
        return run_on_numbers_or_strings(">", expr.operator, left, right)
      when .greater_equal?
        return run_on_numbers_or_strings(">=", expr.operator, left, right)
      when .less?
        return run_on_numbers_or_strings("<", expr.operator, left, right)
      when .less_equal?
        return run_on_numbers_or_strings("<=", expr.operator, left, right)
      when .bang_equal?
        return !equal?(left, right)
      when .equal_equal?
        return equal?(left, right)
      when .plus?
        return run_on_numbers_or_strings("+", expr.operator, left, right)
      when .minus?
        check_number_operands(expr.operator, left, right)

        return left.as(Float64) - right.as(Float64)
      when .star?
        # TODO: Add support for string * number
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

    def visit_assign_expr(expr) : Obj
      value = evaluate(expr.value)
      environment.assign(expr.name, value)

      value
    end

    def visit_ternary_expr(expr) : Obj
      cond = evaluate(expr.condition)

      truthy?(cond) ? evaluate(expr.left) : evaluate(expr.right)
    end

    def visit_logical_expr(expr) : Obj
      left = evaluate(expr.left)

      case expr.operator.type
      when .or?
        return left if truthy?(left)
      when .and?
        return left if falsey?(left)
      else
        runtime_error(expr.operator, "Unknown logical operator. This is probably a parsing error. My bad =(")
      end

      evaluate(expr.right)
    end

    def visit_variable_expr(expr) : Obj
      @environment.get(expr.name)
    end

    def execute(stmt : Stmt) : Obj
      stmt.accept(self)
    end

    def evaluate(expr : Expr) : Obj
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

    private def falsey?(obj : Obj) : Bool
      !obj
    end

    private def equal?(a : Obj, b : Obj) : Bool
      return true if a.nil? && b.nil?
      return false if a.nil?

      a == b
    end

    private def stringify(obj : Obj) : String
      return "nil" if obj.nil?
      return obj.to_s.rchop(".0") if obj.is_a? Float64

      obj.to_s
    end

    private def runtime_error(token, msg)
      raise RuntimeError.new(token, msg)
    end

    private macro run_on_numbers_or_strings(operation, expr_token, left, right)
      if left.is_a? Float64 && right.is_a? Float64
        return left.as(Float64) {{ operation.id }} right.as(Float64)
      end

      if left.is_a? String && right.is_a? String
        return left.as(String) {{ operation.id }} right.as(String)
      end

      runtime_error({{ expr_token }}, "Operands must be two numbers or two strings.")
    end
  end
end
