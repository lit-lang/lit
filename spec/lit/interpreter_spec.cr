require "../spec_helper"

describe Lit::Interpreter, focus: true do
  interpreter = Lit::Interpreter.new([] of Lit::Expr)

  describe "#visit_literal_expr" do
    it "interprets literals" do
      expr = Create.expr(:literal)

      interpreter.evaluate(expr).should eq 1.0
    end
  end

  describe "#visit_unary_expr" do
    it "interprets minus operator" do
      expr = Create.expr(:unary)

      interpreter.evaluate(expr).should eq -1.0
    end

    it "interprets bang operator" do
      bang = Create.token(:bang)
      true_literal = Create.expr(:literal, true)
      expr = Create.expr(:unary, operator: bang, right: true_literal)

      interpreter.evaluate(expr).should eq false
    end

    context "when is an invalid operation" do
      it "raises a runtime error" do
        minus = Create.token(:minus)
        string_literal = Create.expr(:literal, "a string")
        expr = Create.expr(:unary, operator: minus, right: string_literal)

        expect_raises(Lit::RuntimeError, /Operand must be a number/) do
          interpreter.evaluate(expr)
        end
      end
    end

    context "when is an unkown operation" do
      it "raises a runtime error" do
        plus = Create.token(:plus)
        string_literal = Create.expr(:literal, "a string")
        expr = Create.expr(:unary, operator: plus, right: string_literal)

        expect_raises(Lit::RuntimeError, /Unknown unary operator/) do
          interpreter.evaluate(expr)
        end
      end
    end
  end
end
