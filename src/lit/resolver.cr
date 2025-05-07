require "./lit"
require "./expr"
require "./stmt"

module Lit
  class Resolver
    include Expr::Visitor(Nil)
    include Stmt::Visitor(Nil)

    enum FunctionType
      None
      Function
      Method
      Initializer
    end

    # TODO: this can be renamed or use a bool instead
    enum TypeType
      None
      Type
    end

    def initialize(interpreter : Interpreter, error_reporter : ErrorReporter)
      @interpreter = interpreter
      @error_reporter = error_reporter
      @scopes = [] of Hash(String, Bool)
      @current_function = FunctionType::None
      @current_type = TypeType::None
      @loop_depth = 0
    end

    private getter scopes

    def resolve(stmts : Array(Stmt)) : Nil
      stmts.each { |stmt| resolve(stmt) }
    end

    def visit_type_stmt(stmt) : Nil
      enclosing_type = @current_type
      @current_type = TypeType::Type
      declare(stmt.name)
      define(stmt.name)

      begin_scope
      scopes.last["self"] = true

      stmt.methods.each do |method|
        declaration = FunctionType::Method
        if method.name.lexeme == "init"
          declaration = FunctionType::Initializer
        end
        resolve_function(method.function, declaration)
      end

      end_scope
      @current_type = enclosing_type
    end

    def visit_if_expr(expr) : Nil
      resolve(expr.condition)
      resolve(expr.then_branch)
      resolve(expr.else_branch.not_nil!) if expr.else_branch
    end

    def visit_while_stmt(stmt) : Nil
      with_loop_scope do
        resolve(stmt.condition)
        resolve(stmt.body)
      end
    end

    def visit_loop_stmt(stmt) : Nil
      with_loop_scope do
        resolve(stmt.body)
      end
    end

    def visit_break_stmt(stmt) : Nil
      if @loop_depth == 0
        @error_reporter.report_syntax_error(stmt.keyword, "Can't use 'break' outside of a loop.")
      end
    end

    def visit_next_stmt(stmt) : Nil
      if @loop_depth == 0
        @error_reporter.report_syntax_error(stmt.keyword, "Can't use 'next' outside of a loop.")
      end
    end

    def visit_block_expr(expr) : Nil
      begin_scope
      resolve(expr.statements)
      end_scope
    end

    def visit_function_stmt(stmt) : Nil
      declare(stmt.name)
      define(stmt.name)
      resolve_function(stmt.function, FunctionType::Function)
    end

    def visit_var_stmt(stmt) : Nil
      declare(stmt.name)
      resolve(stmt.initializer.not_nil!) if stmt.initializer
      define(stmt.name)
    end

    def visit_expression_stmt(stmt) : Nil
      resolve(stmt.expression)
    end

    def visit_return_stmt(stmt) : Nil
      if @current_function.none?
        @error_reporter.report_syntax_error(stmt.keyword, "Can't return from top-level code.")
      end

      if stmt.value
        if @current_function.initializer?
          # TODO: this seems arbitrary. While not ideal, I don't see why being specific about it.
          @error_reporter.report_syntax_error(stmt.keyword, "Can't return a value from an initializer.")
        end
        resolve(stmt.value.not_nil!)
      end
    end

    def visit_call_expr(expr) : Nil
      resolve(expr.callee)
      expr.arguments.each { |arg| resolve(arg) }
    end

    def visit_get_expr(expr) : Nil
      resolve(expr.object)
    end

    def visit_set_expr(expr) : Nil
      resolve(expr.value)
      resolve(expr.object)
    end

    def visit_literal_expr(expr) : Nil
      nil
    end

    def visit_unary_expr(expr) : Nil
      resolve(expr.right)
    end

    def visit_binary_expr(expr) : Nil
      resolve(expr.left)
      resolve(expr.right)
    end

    def visit_grouping_expr(expr) : Nil
      resolve(expr.expression)
    end

    def visit_assign_expr(expr) : Nil
      resolve(expr.value)
      resolve_local(expr, expr.name)
    end

    def visit_ternary_expr(expr) : Nil
      resolve(expr.condition)
      resolve(expr.left)
      resolve(expr.right)
    end

    def visit_logical_expr(expr) : Nil
      resolve(expr.left)
      resolve(expr.right)
    end

    def visit_self_expr(expr) : Nil
      if @current_type == TypeType::None
        @error_reporter.report_syntax_error(expr.keyword, "Can't use 'self' outside of a type.")
      end

      resolve_local(expr, expr.keyword)
    end

    def visit_variable_expr(expr) : Nil
      if !scopes.empty? && scopes.last[expr.name.lexeme]? == false
        @error_reporter.report_syntax_error(expr.name, "Can't read local variable in its own initializer.")
      end

      resolve_local(expr, expr.name)
    end

    def visit_string_interpolation_expr(expr) : Nil
      expr.parts.each { |part| resolve(part) }
    end

    def visit_function_expr(expr) : Nil
      resolve_function(expr, FunctionType::Function)
    end

    def visit_array_literal_expr(expr) : Nil
      expr.elements.each { |element| resolve(element) }
    end

    def visit_map_literal_expr(expr) : Nil
      expr.entries.each do |entry|
        resolve(entry[0])
        resolve(entry[1])
      end
    end

    def resolve(stmt : Stmt) : Nil
      stmt.accept(self)
    end

    def resolve(expr : Expr) : Nil
      expr.accept(self)
    end

    private def resolve_function(stmt, type : FunctionType) : Nil
      enclosing_function_type = @current_function
      @current_function = type
      previous_depth = @loop_depth

      begin_scope
      stmt.params.each do |param|
        declare(param)
        define(param)
      end
      # we allow functions to be defined inside loops, but we don't want to
      # allow break/next to be called inside the functions, so we reset the
      # depth here temporarily
      @loop_depth = 0
      resolve(stmt.body)
      end_scope

      @loop_depth = previous_depth
      @current_function = enclosing_function_type
    end

    private def resolve_local(expr : Expr, name : Token) : Nil
      scopes.reverse_each.with_index do |scope, i|
        if scope.has_key?(name.lexeme)
          @interpreter.resolve(expr, i)
          return
        end
      end
    end

    def with_scope(&)
      begin_scope
      yield
    ensure
      end_scope
    end

    private def begin_scope
      scopes.push({} of String => Bool)
    end

    private def end_scope
      scopes.pop
    end

    private def declare(name)
      return if scopes.empty?

      scope = scopes.last

      if scope.has_key?(name.lexeme)
        @error_reporter.report_syntax_error(name, "Already a variable with this name in this scope.")
      end

      scope[name.lexeme] = false
    end

    private def define(name)
      return if scopes.empty?

      scopes.last[name.lexeme] = true
    end

    private def with_loop_scope(&)
      @loop_depth += 1
      yield
    ensure
      @loop_depth -= 1
    end
  end
end
