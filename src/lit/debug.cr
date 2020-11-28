require "./expr"

module Lit
  module Debug
    extend self

    def s_expr(exprs : Array(Expr)) : String
      exprs.map { |expr| s_expr(expr) }.join("\n")
    end

    def s_expr(expr : Expr::Binary) : String
      parenthesize(expr.operator.lexeme, expr.left, expr.right)
    end

    def s_expr(expr : Expr::Unary) : String
      parenthesize(expr.operator.lexeme, expr.right)
    end

    def s_expr(expr : Expr::Literal) : String
      expr.value.inspect
    end

    def s_expr(expr : Expr::Grouping) : String
      parenthesize("group", expr.expression)
    end

    def s_expr(expr : Expr::Logical) : String
      parenthesize(expr.operator.lexeme, expr.left, expr.right)
    end

    def s_expr(expr : Expr::Variable) : String
      expr.name.lexeme
    end

    def s_expr(expr : Expr::Assign) : String
      parenthesize("= #{expr.name.lexeme}", expr.value)
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
