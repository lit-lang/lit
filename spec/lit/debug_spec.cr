require "../spec_helper"

describe Lit::Debug do
  describe ".s_expr" do
    context "with literal expressions" do
      it do
        expr = Create.expr(:literal, 1.0)

        Lit::Debug.s_expr(expr).should eq "1.0"
      end

      it do
        expr = Create.expr(:literal, true)

        Lit::Debug.s_expr(expr).should eq "true"
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

    context "with logical expressions" do
      it do
        expr = Create.expr(:logical)

        Lit::Debug.s_expr(expr).should eq "(and true true)"
      end
    end

    context "with variable expressions" do
      it do
        expr = Create.expr(:variable)

        Lit::Debug.s_expr(expr).should eq "my_var"
      end
    end

    context "with ternary expressions" do
      it do
        expr = Create.expr(:ternary)

        Lit::Debug.s_expr(expr).should eq "(? true 1.0 2.0)"
      end
    end

    context "with assign expression" do
      it do
        expr = Create.expr(:assign)

        Lit::Debug.s_expr(expr).should eq "(= my_var 1.0)"
      end
    end

    context "with multiple expressions" do
      it do
        expr = [Create.expr(:grouping), Create.expr(:literal, "a string")]

        Lit::Debug.s_expr(expr).should eq %((group 1.0)\n"a string")
      end
    end

    context "with call expressions" do
      it do
        expr = Create.expr(:call)

        Lit::Debug.s_expr(expr).should eq %((call my_var 1.0 1.0))
      end
    end
  end
end
