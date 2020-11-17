require "../spec_helper"

describe Lit::Debug do
  describe ".s_expr" do
    context "with literal expressions" do
      it do
        expr = Create.expr(:literal, 1.0)

        Lit::Debug.s_expr(expr).should eq "1.0"
      end
    end

    context "with grouping expressions" do
      it do
        expr = Create.expr(:grouping)

        Lit::Debug.s_expr(expr).should eq "(group 1.0)"
      end
    end

    context "with unary expressions" do
      it do
        expr = Create.expr(:unary)

        Lit::Debug.s_expr(expr).should eq "(- 1.0)"
      end
    end

    context "with binary expressions" do
      it do
        expr = Create.expr(:binary)

        Lit::Debug.s_expr(expr).should eq "(+ 1.0 1.0)"
      end
    end

    context "with multiple expressions" do
      it do
        expr = [Create.expr(:grouping), Create.expr(:literal, "a string")]

        Lit::Debug.s_expr(expr).should eq %((group 1.0); "a string")
      end
    end
  end
end
