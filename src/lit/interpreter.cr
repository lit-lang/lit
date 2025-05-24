require "./lit"
require "./expr"
require "./stmt"
require "./value"
require "./runtime_error"
require "./environment"
require "./callable"
require "./stdlib/native"
require "./stdlib/lit_array"
require "./stdlib/lit_map"
require "./stdlib/lit_string"
require "./stdlib/lit_integer"
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

    class Break < Exception
      getter value : Value

      def initialize(@value); end
    end

    class Exit < Exception
      getter status : Int64

      def initialize(@status); end
    end

    class Next < Exception; end

    getter environment # current environment
    getter argv : LitArray
    getter error_reporter : ErrorReporter
    @last_value : Value

    def initialize(error_reporter : ErrorReporter)
      @error_reporter = error_reporter
      @imported_files = Set(String).new
      @locals = {} of Expr => Int32
      @globals = Environment.new
      Stdlib::Native.all.each do |fn|
        @globals.define(fn.name, fn)
      end
      @environment = @globals
      @in_initializer = false
      @last_value = nil
      @argv = LitArray.new.tap do |a|
        if !ARGV.empty?
          ARGV[1..].each do |arg|
            a.elements.push(arg)
          end
        end
      end
    end

    def interpret(stmts) : Value
      stmts.each { |stmt| execute(stmt) }
      @last_value
    rescue e : RuntimeError
      @error_reporter.report_runtime_error(e)
    end

    def visit_type_stmt(stmt) : Nil
      environment.define(stmt.name.lexeme, UNINITIALIZED)

      methods = {} of String => Function
      stmt.methods.each do |method|
        function = Function.new(method.name.lexeme, method.function, @environment, initializer: method.name.lexeme == "init", method: true)
        methods[method.name.lexeme] = function
      end
      type = Type.new(stmt.name.lexeme, methods)

      environment.assign(stmt.name, type)
    end

    def visit_if_expr(expr) : Value
      @last_value = if truthy?(evaluate(expr.condition))
                      evaluate(expr.then_branch)
                    elsif expr.else_branch
                      evaluate(expr.else_branch.not_nil!)
                    end
    end

    def visit_match_expr(expr) : Value
      subject = evaluate(expr.subject)

      result = expr.branches.find do |(expr_pattern, body)|
        if expr_pattern.is_a?(Expr::Variable) && expr_pattern.name.lexeme == "_"
          true
        else
          pattern = evaluate(expr_pattern)
          if equal?(subject, pattern, expr.keyword)
            true
          elsif subject.is_a?(Instance) && subject.has_type?(pattern)
            true
          else
            false
          end
        end
      end

      if result
        evaluate(result[1].not_nil!)
      else
        runtime_error(expr.keyword, "No match found for #{::Lit.inspect_value(subject, self, expr.keyword)}.")
      end
    end

    def visit_while_expr(expr) : Value
      return_value = nil

      while truthy?(evaluate(expr.condition))
        begin
          return_value = evaluate(expr.body)
        rescue e : Break
          return_value = e.value
          break
        rescue e : Next
          return_value = nil
          next
        end
      end

      return_value
    end

    def visit_loop_expr(expr) : Value
      return_value = nil

      loop do
        begin
          return_value = nil
          evaluate(expr.body)
        rescue e : Break
          return_value = e.value
          break
        rescue e : Next
          return_value = nil
          next
        end
      end

      return_value
    end

    def visit_break_expr(expr) : Nil
      value = expr.value ? evaluate(expr.value.not_nil!) : nil

      raise Break.new(value)
    end

    def visit_next_expr(expr) : Nil
      raise Next.new
    end

    def visit_block_expr(expr) : Value
      execute_block(expr.statements, Environment.new(@environment), @in_initializer)
    rescue e : Exception
      raise e if e.is_a?(Break) || e.is_a?(Next) || e.is_a?(Return) || e.is_a?(RuntimeError) || e.is_a?(Exit)
      # I don't know why this rescue clause is necessary at all. If I remove it,
      # suddenly Break is not rescued anymore. I think this is a bug in the
      # compiler, because if I add a dummy rescue clause with any kind of
      # exception, it works again.
      puts "WTF? #{e.class} #{e.message}"
      abort "WTF? #{e.class} #{e.message}"
    end

    def visit_function_stmt(stmt) : Nil
      function = Function.new(stmt.name.lexeme, stmt.function, @environment, initializer: false, method: false)
      @environment.define(stmt.name.lexeme, function)
    end

    def visit_var_stmt(stmt) : Nil
      @environment.define(stmt.name.lexeme, evaluate(stmt.initializer), stmt.mutable?)
    end

    def visit_expression_stmt(stmt) : Nil
      evaluate(stmt.expression)
    end

    def visit_return_expr(expr) : Nil
      value = expr.value ? evaluate(expr.value.not_nil!) : nil

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

      s = function.arity == 1 ? "" : "s"
      type = if callee.is_a? Type
               "Type"
             elsif callee.as(Function).method?
               "Method"
             else
               "Function"
             end
      runtime_error(expr.paren, "#{type} '#{function.name}' expected #{function.arity} argument#{s} but got #{arguments.size}.")
    end

    def visit_get_expr(expr) : Value
      object = evaluate(expr.object)

      if instance = box(object)
        return instance.get(expr.name)
      end

      runtime_error(expr.name, "Only instances have properties, got #{type_of(object)}.")
    end

    def visit_set_expr(expr) : Value
      object = evaluate(expr.object)

      if !object.is_a? Instance
        raise RuntimeError.new(expr.name, "Only instances have fields.")
      end

      value = evaluate(expr.value)
      object.set(expr.name, value, @in_initializer)
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
        if right.is_a?(Number)
          return -right
        elsif right.is_a? Instance
          return right.call_method(expr.operator.with_lexeme("neg"), ([] of Value), self)
        else
          return runtime_error(expr.operator, "Right side operand of type #{type_of(right)} must implement the 'neg' method.")
        end
      when .bang?
        return falsey?(right)
      end

      runtime_error(expr.operator, "Unknown unary operator #{expr.operator}. This is probably a parsing bug. My bad =(")
    end

    def visit_binary_expr(expr) : Value
      if expr.operator.type.pipe_greater?
        right = expr.right.as(Expr::Call)
        call = Expr::Call.new(right.callee, right.paren, [expr.left] + right.arguments)

        return evaluate(call)
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
      Function.new(nil, expr, @environment, initializer: false, method: false)
    end

    def visit_array_literal_expr(expr) : Value
      elements = expr.elements.map { |e| evaluate(e) }
      LitArray.new(elements)
    end

    def visit_map_literal_expr(expr) : Value
      map = LitMap.new
      expr.entries.each do |entry|
        key = evaluate(entry[0])
        value = evaluate(entry[1])

        # TODO: warn on duplicate keys
        map.elements[key] = value
      end
      map
    end

    def visit_import_expr(expr) : Nil
      file = expr.path.literal.as(String)
      file = file.ends_with?(".lit") ? file : "#{file}.lit"
      file_path = ::Lit.expand_path(file)
      return if !@imported_files.add?(file_path)

      result = Lit.read_file(file_path)
      ::Lit.with_current_file_path(file_path) do
        if result.is_a?(String)
          tokens = Scanner.new(result, @error_reporter).scan
          statements = Parser.new(tokens, @error_reporter).parse
          raise Exit.new(ExitCode::DATAERR.to_i) if @error_reporter.had_syntax_error?
          Resolver.new(self, @error_reporter).resolve(statements)
          raise Exit.new(ExitCode::DATAERR.to_i) if @error_reporter.had_syntax_error?

          interpret(statements)
        else
          if result[0].is_a?(ExitCode)
            runtime_error(expr.path, result[1])
            exit(result[0].to_i)
          else
            raise "Bug in the interpreter: unexpected result from read_file: #{result.inspect}"
          end
        end
      end
    end

    def execute(stmt : Stmt) : Value
      @last_value = nil
      stmt.accept(self)
    end

    def evaluate(expr : Expr) : Value
      @last_value = expr.accept(self)
    end

    def execute_block(stmts : Array(Stmt), environment : Environment, in_initializer : Bool) : Value
      previous = {@environment, @in_initializer}
      @last_value = nil # reset in case block is empty

      begin
        @environment = environment
        @in_initializer = in_initializer
        stmts.each { |stmt| execute(stmt) }
      ensure
        @environment, @in_initializer = previous
      end

      @last_value
    end

    def resolve(expr, depth)
      @locals[expr] = depth
    end

    def type_of(value : Value) : String
      case value
      in Float64
        "Float"
      in Int64
        "Integer"
      in ::Lit::Native::Fn
        "Function"
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

    private def equal?(a : Value, b : Value, token : Token) : Bool
      # p! a
      # p! b
      return true if a.nil? && b.nil?
      return false if a.nil?

      if a.is_a?(LitArray)
        # puts "a is a LitArray"
        return false if !b.is_a?(LitArray)
        # puts "b is a LitArray"
        return a.elements.each_with_index.all? { |value, i| equal?(value, b.elements[i]?, token) }
      end
      if a.is_a?(LitMap)
        return false if !b.is_a?(LitMap)
        return a.elements.each_with_index.all? { |(key, value), i| equal?(value, b.elements[key]?, token) }
      end

      if a.is_a?(Instance) && (instance_eq = a.as(Instance).get_method(token.with_lexeme(BINARY_OP_TO_METHOD[:==])))
        return truthy?(instance_eq.call(self, [b], token))
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
      when Int64
        LitInteger.new(value)
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
      # Float operations
      if left.is_a? Float && right.is_a? Number
        return left {{ operation.id }} right
      end
      # Int operations
      if left.is_a? Int64
        {% if operation == "%" %}
          if right.is_a? Int64
            return left {{ operation.id }} right
          end
          if right.is_a? Float64
            # Crystal doesn't support Int % Float, so we need to convert left to
            # float for modulus with another float
            return left.to_f {{ operation.id }} right
          end
        {% elsif operation == "/" %}
          if right.is_a? Int64
            begin
              return left // right
            rescue DivisionByZeroError
              runtime_error({{ expr_token }}, "Division by zero.")
            end
          elsif right.is_a? Float64
            return left / right
          end
        {% else %}
          if right.is_a? Number
            return left {{ operation.id }} right
          end
        {% end %}
      end

      # String operations
      {% if operation != "-" && operation != "*" && operation != "/" && operation != "%" %}
        if left.is_a? String && right.is_a? String
          return left {{ operation.id }} right
        end
      {% end %}

      # For instances, go through normal method dispatch
      if left.is_a? Instance
        return left.call_method({{expr_token}}.with_lexeme(BINARY_OP_TO_METHOD[{{ operation }}]), [right], self)
      end

      runtime_error({{ expr_token }}, "Undefined operator #{{{operation}}} for #{type_of(left)} and #{type_of(right)}.")
    end
  end
end
