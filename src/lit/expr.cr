require "./token"

module Lit
  abstract class Expr
    module Visitor
      abstract def visit_literal_expr(expr : Literal)
    end

    class Literal < Expr
      getter value : Union(String | Float64 | Bool | Nil)

      def initialize(@value); end

      def accept(visitor : Visitor)
        visitor.visit_literal_expr(self)
      end
    end

    abstract def accept(visitor : Visitor)
  end
end
