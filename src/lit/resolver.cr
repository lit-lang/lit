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

    def initialize(interpreter : Interpreter)
      @interpreter = interpreter
      @scopes = [] of Hash(String, Bool)
      @current_function = FunctionType::None
      @current_type = TypeType::None
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
        resolve_function(method, declaration)
      end

      end_scope
      @current_type = enclosing_type
    end

    def visit_if_stmt(stmt) : Nil
      resolve(stmt.condition)
      resolve(stmt.then_branch)
      resolve(stmt.else_branch.not_nil!) if stmt.else_branch
    end

    def visit_while_stmt(stmt) : Nil
      resolve(stmt.condition)
      resolve(stmt.body)
    end

    def visit_loop_stmt(stmt) : Nil
      resolve(stmt.body)
    end

    def visit_println_stmt(stmt) : Nil
      resolve(stmt.expression)
    end

    def visit_print_stmt(stmt) : Nil
      resolve(stmt.expression)
    end

    def visit_block_stmt(stmt) : Nil
      begin_scope
      resolve(stmt.statements)
      end_scope
    end

    def visit_function_stmt(stmt) : Nil
      declare(stmt.name)
      define(stmt.name)
      resolve_function(stmt, FunctionType::Function)
    end

    def visit_let_stmt(stmt) : Nil
      declare(stmt.name)
      resolve(stmt.initializer.not_nil!) if stmt.initializer
      define(stmt.name)
    end

    def visit_expression_stmt(stmt) : Nil
      resolve(stmt.expression)
    end

    def visit_return_stmt(stmt) : Nil
      if @current_function.none?
        Lit.error(stmt.keyword, "Can't return from top-level code.")
      end

      if stmt.value
        if @current_function.initializer?
          # TODO: this seems arbitrary. While not ideal, I don't see why being specific about it.
          Lit.error(stmt.keyword, "Can't return a value from an initializer.")
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
        Lit.error(expr.keyword, "Can't use 'self' outside of a type.")
      end

      resolve_local(expr, expr.keyword)
    end

    def visit_variable_expr(expr) : Nil
      if !scopes.empty? && scopes.last[expr.name.lexeme]? == false
        Lit.error(expr.name, "Can't read local variable in its own initializer.")
      end

      resolve_local(expr, expr.name)
    end

    def resolve(stmt : Stmt) : Nil
      stmt.accept(self)
    end

    def resolve(expr : Expr) : Nil
      expr.accept(self)
    end

    private def resolve_function(stmt, type : FunctionType) : Nil
      enclosing_function = @current_function
      @current_function = type

      begin_scope
      stmt.params.each do |param|
        declare(param)
        define(param)
      end
      resolve(stmt.body)
      end_scope

      @current_function = enclosing_function
    end

    private def resolve_local(expr : Expr, name : Token) : Nil
      scopes.reverse_each.with_index do |scope, i|
        if scope.has_key?(name.lexeme)
          @interpreter.resolve(expr, i)
          return
        end
      end
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
        Lit.error(name, "Already a variable with this name in this scope.")
      end

      scope[name.lexeme] = false
    end

    private def define(name)
      return if scopes.empty?

      scopes.last[name.lexeme] = true
    end
  end
end
