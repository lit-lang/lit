# WARNING: This file is autogenerated! Please, don't edit it directly.

require "./token"

module Lit
  abstract class Stmt
    module Visitor(T)
      abstract def visit_block_stmt(stmt : Block) : T
      abstract def visit_break_stmt(stmt : Break) : T
      abstract def visit_next_stmt(stmt : Next) : T
      abstract def visit_type_stmt(stmt : Type) : T
      abstract def visit_expression_stmt(stmt : Expression) : T
      abstract def visit_function_stmt(stmt : Function) : T
      abstract def visit_if_stmt(stmt : If) : T
      abstract def visit_println_stmt(stmt : Println) : T
      abstract def visit_print_stmt(stmt : Print) : T
      abstract def visit_return_stmt(stmt : Return) : T
      abstract def visit_var_stmt(stmt : Var) : T
      abstract def visit_loop_stmt(stmt : Loop) : T
      abstract def visit_while_stmt(stmt : While) : T
    end

    class Block < Stmt
      getter statements : Array(Stmt)

      def initialize(@statements); end

      def accept(visitor : Visitor)
        visitor.visit_block_stmt(self)
      end
    end

    class Break < Stmt
      getter keyword : Token

      def initialize(@keyword); end

      def accept(visitor : Visitor)
        visitor.visit_break_stmt(self)
      end
    end

    class Next < Stmt
      getter keyword : Token

      def initialize(@keyword); end

      def accept(visitor : Visitor)
        visitor.visit_next_stmt(self)
      end
    end

    class Type < Stmt
      getter name : Token
      getter methods : Array(Stmt::Function)

      def initialize(@name, @methods); end

      def accept(visitor : Visitor)
        visitor.visit_type_stmt(self)
      end
    end

    class Expression < Stmt
      getter expression : Expr

      def initialize(@expression); end

      def accept(visitor : Visitor)
        visitor.visit_expression_stmt(self)
      end
    end

    class Function < Stmt
      getter name : Token
      getter function : Expr::Function

      def initialize(@name, @function); end

      def accept(visitor : Visitor)
        visitor.visit_function_stmt(self)
      end
    end

    class If < Stmt
      getter condition : Expr
      getter then_branch : Stmt
      getter else_branch : Stmt?

      def initialize(@condition, @then_branch, @else_branch); end

      def accept(visitor : Visitor)
        visitor.visit_if_stmt(self)
      end
    end

    class Println < Stmt
      getter keyword : Token
      getter expression : Expr

      def initialize(@keyword, @expression); end

      def accept(visitor : Visitor)
        visitor.visit_println_stmt(self)
      end
    end

    class Print < Stmt
      getter keyword : Token
      getter expression : Expr

      def initialize(@keyword, @expression); end

      def accept(visitor : Visitor)
        visitor.visit_print_stmt(self)
      end
    end

    class Return < Stmt
      getter keyword : Token
      getter value : Expr?

      def initialize(@keyword, @value); end

      def accept(visitor : Visitor)
        visitor.visit_return_stmt(self)
      end
    end

    class Var < Stmt
      getter name : Token
      getter initializer : Expr
      getter? mutable : Bool

      def initialize(@name, @initializer, @mutable); end

      def accept(visitor : Visitor)
        visitor.visit_var_stmt(self)
      end
    end

    class Loop < Stmt
      getter body : Stmt

      def initialize(@body); end

      def accept(visitor : Visitor)
        visitor.visit_loop_stmt(self)
      end
    end

    class While < Stmt
      getter condition : Expr
      getter body : Stmt

      def initialize(@condition, @body); end

      def accept(visitor : Visitor)
        visitor.visit_while_stmt(self)
      end
    end

    abstract def accept(visitor : Visitor)
  end
end
