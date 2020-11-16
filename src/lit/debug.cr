require "./expr"

module Lit
  module Debug
    extend self

    def s_expr(exprs : Array(Expr)) : String
      exprs.map { |expr| s_expr(expr) }.join("; ")
    end

    def s_expr(expr : Expr::Literal) : String
      expr.value.to_s
    end

    def s_expr(expr : Expr::Grouping) : String
      parenthesize("group", expr.expression)
    end

    private def parenthesize(name : String, *exprs) : String
      str = "(#{name}"

      exprs.each do |expr|
        str += " "
        str += s_expr(expr)
      end
      str += ")"

      str
    end
  end
end
