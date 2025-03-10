# WARNING: This file is autogenerated! Please, don't edit it directly.

require "./token"

module Lit
  abstract class Stmt
    module Visitor
      abstract def visit_expression_stmt(stmt : Expression)
      abstract def visit_println_stmt(stmt : Println)
      abstract def visit_print_stmt(stmt : Print)
      abstract def visit_let_stmt(stmt : Let)
    end

    class Expression < Stmt
      getter expression : Expr

      def initialize(@expression); end

      def accept(visitor : Visitor)
        visitor.visit_expression_stmt(self)
      end
    end

    class Println < Stmt
      getter expression : Expr

      def initialize(@expression); end

      def accept(visitor : Visitor)
        visitor.visit_println_stmt(self)
      end
    end

    class Print < Stmt
      getter expression : Expr

      def initialize(@expression); end

      def accept(visitor : Visitor)
        visitor.visit_print_stmt(self)
      end
    end

    class Let < Stmt
      getter name : Token
      getter initializer : Expr

      def initialize(@name, @initializer); end

      def accept(visitor : Visitor)
        visitor.visit_let_stmt(self)
      end
    end

    abstract def accept(visitor : Visitor)
  end
end
