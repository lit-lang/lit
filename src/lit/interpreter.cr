require "./lit"
require "./expr"
require "./stmt"
require "./value"
require "./runtime_error"
require "./environment"
require "./callable"
require "./native"
require "./function"
require "./type"
require "./instance"

module Lit
  class Interpreter
    include Expr::Visitor(Value)
    include Stmt::Visitor(Value)

    class Return < Exception
      getter value : Value

      def initialize(@value); end
    end

    class Break < Exception
    end

    class Next < Exception
    end

    getter environment # current environment

    def initialize
      @locals = {} of Expr => Int32
      @globals = Environment.new
      @globals.define("clock", Clock.new)
      @environment = @globals
    end

    def self.interpret(stmts : Array(Stmt))
      new.interpret(stmts)
    end

    def interpret(stmts) : Nil
      stmts.each { |stmt| execute(stmt) }
    rescue e : RuntimeError
      Lit.runtime_error(e)
    end

    def visit_type_stmt(stmt) : Nil
      environment.define(stmt.name.lexeme, nil)

      methods = {} of String => Function
      stmt.methods.each do |method|
        function = Function.new(method, @environment, initializer: method.name.lexeme == "init")
        methods[method.name.lexeme] = function
      end
      type = Type.new(stmt.name.lexeme, methods)

      environment.assign(stmt.name, type)
    end

    def visit_if_stmt(stmt) : Nil
      if truthy?(evaluate(stmt.condition))
        execute(stmt.then_branch)
      elsif stmt.else_branch
        execute(stmt.else_branch.not_nil!)
      end
    end

    def visit_while_stmt(stmt) : Nil
      while truthy?(evaluate(stmt.condition))
        begin
          execute(stmt.body)
        rescue e : Break
          break
        rescue e : Next
          next
        end
      end
    end

    def visit_loop_stmt(stmt) : Nil
      loop do
        begin
          execute(stmt.body)
        rescue e : Break
          break
        rescue e : Next
          next
        end
      end
    end

    def visit_break_stmt(stmt) : Nil
      raise Break.new(nil)
    end

    def visit_next_stmt(stmt) : Nil
      raise Next.new(nil)
    end

    def visit_println_stmt(stmt) : Nil
      puts stringify(evaluate(stmt.expression))
    end

    def visit_print_stmt(stmt) : Nil
      print stringify(evaluate(stmt.expression))
    end

    def visit_block_stmt(stmt) : Nil
      execute_block(stmt.statements, Environment.new(@environment))
    end

    def visit_function_stmt(stmt) : Nil
      function = Function.new(stmt, @environment, false)
      @environment.define(stmt.name.lexeme, function)
    end

    def visit_let_stmt(stmt) : Nil
      @environment.define(stmt.name.lexeme, evaluate(stmt.initializer))
    end

    def visit_expression_stmt(stmt) : Nil
      evaluate(stmt.expression)
    end

    def visit_return_stmt(stmt) : Nil
      value = stmt.value ? evaluate(stmt.value.not_nil!) : nil

      raise Return.new(value)
    end

    def visit_call_expr(expr) : Value
      callee = evaluate(expr.callee)
      arguments = expr.arguments.map { |arg| evaluate(arg) }

      if !callee.is_a? Callable
        runtime_error(expr.paren, "Can only call functions and types.")
      end

      function = callee.as(Callable)
      if arguments.size != function.arity
        runtime_error(expr.paren, "Expected #{function.arity} arguments but got #{arguments.size}.")
      end

      function.call(self, arguments)
    end

    def visit_get_expr(expr) : Value
      object = evaluate(expr.object)

      if object.is_a? Instance
        return object.as(Instance).get(expr.name)
      end

      runtime_error(expr.name, "Only instances have properties.")
    end

    def visit_set_expr(expr) : Value
      object = evaluate(expr.object)

      if !object.is_a? Instance
        raise RuntimeError.new(expr.name, "Only instances have fields.")
      end

      value = evaluate(expr.value)
      object.as(Instance).set(expr.name, value)
      value
    end

    def visit_self_expr(expr) : Value
      lookup_variable(expr.keyword, expr)
    end

    def visit_literal_expr(expr) : Value
      expr.value
    end

    def visit_unary_expr(expr) : Value
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

    def visit_binary_expr(expr) : Value
      if expr.operator.type.pipe_operator?
        expr.right.as(Expr::Call).arguments.unshift(expr.left)
        return evaluate(expr.right)
      end

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
      when .percent?
        check_number_operands(expr.operator, left, right)

        return left.as(Float64) % right.as(Float64)
      end

      runtime_error(expr.operator, "Unknown binary operator. This is probably a parsing error. My bad =(")
    end

    def visit_grouping_expr(expr) : Value
      evaluate(expr.expression)
    end

    def visit_assign_expr(expr) : Value
      value = evaluate(expr.value)

      if distance = @locals[expr]?
        @environment.assign_at(distance, expr.name, value)
      else
        @globals.assign(expr.name, value)
      end

      value
    end

    def visit_ternary_expr(expr) : Value
      cond = evaluate(expr.condition)

      truthy?(cond) ? evaluate(expr.left) : evaluate(expr.right)
    end

    def visit_logical_expr(expr) : Value
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

    def visit_variable_expr(expr) : Value
      lookup_variable(expr.name, expr)
    end

    def execute(stmt : Stmt) : Value
      stmt.accept(self)
    end

    def evaluate(expr : Expr) : Value
      expr.accept(self)
    end

    def execute_block(stmts : Array(Stmt), environment : Environment) : Nil
      previous = @environment

      begin
        @environment = environment
        stmts.each { |stmt| execute(stmt) }
      ensure
        @environment = previous
      end
    end

    def resolve(expr, depth)
      @locals[expr] = depth
    end

    private def lookup_variable(name : Token, expr : Expr) : Value
      if distance = @locals[expr]?
        @environment.get_at(distance, name.lexeme)
      else
        @globals.get(name)
      end
    end

    private def check_number_operand(operator, operand : Value)
      return if operand.is_a? Float64

      runtime_error(operator, "Operand must be a number.")
    end

    private def check_number_operands(operator, left : Value, right : Value)
      return if left.is_a? Float64 && right.is_a? Float64

      runtime_error(operator, "Operands must be two numbers or two strings.")
    end

    private def truthy?(value : Value) : Bool
      !!value
    end

    private def falsey?(value : Value) : Bool
      !value
    end

    private def equal?(a : Value, b : Value) : Bool
      return true if a.nil? && b.nil?
      return false if a.nil?

      a == b
    end

    private def stringify(value : Value) : String
      return "nil" if value.nil?
      return value.to_s.rchop(".0") if value.is_a? Float64

      value.to_s
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
