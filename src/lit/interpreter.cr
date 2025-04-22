require "./lit"
require "./expr"
require "./stmt"
require "./value"
require "./runtime_error"
require "./environment"
require "./callable"
require "./stdlib/native"
require "./stdlib/lit_array"
require "./stdlib/lit_string"
require "./stdlib/lit_float"
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

    class Break < Exception; end

    class Next < Exception; end

    getter environment # current environment

    def initialize
      @locals = {} of Expr => Int32
      @globals = Environment.new
      Stdlib::Native.all.each do |fn|
        @globals.define(fn.name, fn)
      end
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
      environment.define(stmt.name.lexeme, UNINITIALIZED)

      methods = {} of String => Function
      stmt.methods.each do |method|
        function = Function.new(method.name.lexeme, method.function, @environment, initializer: method.name.lexeme == "init")
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
      puts ::Lit.stringify_value(evaluate(stmt.expression), self, stmt.keyword)
    end

    def visit_print_stmt(stmt) : Nil
      print ::Lit.stringify_value(evaluate(stmt.expression), self, stmt.keyword)
    end

    def visit_block_stmt(stmt) : Nil
      execute_block(stmt.statements, Environment.new(@environment))
    end

    def visit_function_stmt(stmt) : Nil
      function = Function.new(stmt.name.lexeme, stmt.function, @environment, false)
      @environment.define(stmt.name.lexeme, function)
    end

    def visit_var_stmt(stmt) : Nil
      @environment.define(stmt.name.lexeme, evaluate(stmt.initializer), stmt.mutable?)
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
      if function.arity === arguments.size
        return function.call(self, arguments, expr.paren)
      end

      runtime_error(expr.paren, "Expected #{function.arity} arguments but got #{arguments.size}.")
    end

    def visit_get_expr(expr) : Value
      object = evaluate(expr.object)

      if instance = box(object)
        return instance.get(expr.name)
      end
      # if object.is_a? Instance
      # return object.as(Instance).get(expr.name)
      # # end

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
        if right.is_a?(Float64)
          return -right.as(Float64)
        elsif right.is_a? Instance
          return right.as(Instance).call_method(expr.operator.with_lexeme("neg"), ([] of Value), self)
        else
          return runtime_error(expr.operator, "Operand must be a number or implement the 'neg' method.")
        end
      when .bang?
        return falsey?(right)
      end

      runtime_error(expr.operator, "Unknown unary operator #{expr.operator}. This is probably a parsing error. My bad =(")
    end

    def visit_binary_expr(expr) : Value
      if expr.operator.type.pipe_greater?
        expr.right.as(Expr::Call).arguments.unshift(expr.left)
        return evaluate(expr.right)
      end

      left = evaluate(expr.left)
      right = evaluate(expr.right)

      case expr.operator.type
      when .greater?
        return apply_binary_operator(">", expr.operator, left, right)
      when .greater_equal?
        return apply_binary_operator(">=", expr.operator, left, right)
      when .less?
        return apply_binary_operator("<", expr.operator, left, right)
      when .less_equal?
        return apply_binary_operator("<=", expr.operator, left, right)
      when .bang_equal?
        return !equal?(left, right, expr.operator)
      when .equal_equal?
        return equal?(left, right, expr.operator)
      when .plus?
        return apply_binary_operator("+", expr.operator, left, right)
      when .minus?
        return apply_binary_operator("-", expr.operator, left, right)
      when .star?
        return apply_binary_operator("*", expr.operator, left, right)
      when .slash?
        return apply_binary_operator("/", expr.operator, left, right)
      when .percent?
        return apply_binary_operator("%", expr.operator, left, right)
      end

      runtime_error(expr.operator, "Unknown binary operator #{expr.operator.inspect}. This is probably a parsing error. My bad =(")
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
        runtime_error(expr.operator, "Unknown logical operator #{expr.operator}. This is probably a parsing error. My bad =(")
      end

      evaluate(expr.right)
    end

    def visit_variable_expr(expr) : Value
      lookup_variable(expr.name, expr)
    end

    def visit_string_interpolation_expr(expr) : String
      String.build do |s|
        expr.parts.each do |e|
          s << ::Lit.stringify_value(evaluate(e), self, expr.token)
        end
      end
    end

    def visit_function_expr(expr) : Value
      Function.new(nil, expr, @environment, initializer: false)
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

    def type_of(value : Value) : String
      case value
      in Float64
        "Number"
      in String, Bool, Nil, Type, Function
        value.class.name.split("::").last
      in Instance
        value.type.name
      in Uninitialized, Callable
        raise "Bug in the interpreter: can't find type of #{value.inspect}"
      end
    end

    private def lookup_variable(name : Token, expr : Expr) : Value
      if distance = @locals[expr]?
        @environment.get_at(distance, name.lexeme)
      else
        @globals.get(name)
      end
    end

    private def truthy?(value : Value) : Bool
      !!value
    end

    private def falsey?(value : Value) : Bool
      !value
    end

    private def equal?(a : Value, b : Value, token) : Bool
      return true if a.nil? && b.nil?
      return false if a.nil?
      if a.is_a?(Instance) && (method = a.as(Instance).get_method(token.with_lexeme(BINARY_OP_TO_METHOD[:==])))
        return truthy?(method.call(self, [b], token))
      end

      a == b
    end

    private def box(value : Value) : Instance?
      case value
      when Instance
        value
      when String
        LitString.new(value)
      when Float64
        LitFloat.new(value)
      else
        nil
      end
    end

    private def runtime_error(token, msg)
      raise RuntimeError.new(token, msg)
    end

    BINARY_OP_TO_METHOD = {
      "+":  "add",
      "-":  "sub",
      "*":  "mul",
      "/":  "div",
      "%":  "mod",
      ">":  "gt",
      ">=": "gte",
      "<":  "lt",
      "<=": "lte",
      "==": "eq",
    }

    private macro apply_binary_operator(operation, expr_token, left, right)
      if left.is_a? Float64 && right.is_a? Float64
        return left.as(Float64) {{ operation.id }} right.as(Float64)
      end

      {% if operation != "-" && operation != "*" && operation != "/" && operation != "%" %}
        if left.is_a? String && right.is_a? String
          return left.as(String) {{ operation.id }} right.as(String)
        end
      {% end %}

      if left.is_a? Instance
        return left.as(Instance).call_method({{expr_token}}.with_lexeme(BINARY_OP_TO_METHOD[{{ operation }}]), [right], self)
      end

      runtime_error({{ expr_token }}, "Undefined operator #{{{operation}}} for #{type_of(left)} and #{type_of(right)}.")
    end
  end
end
