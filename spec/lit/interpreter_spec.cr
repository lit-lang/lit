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

    # context "when is an invalid operation" do
    #   it "raises a runtime error" do
    #     expr = Create.expr(:unary)
    #     interpreter.evaluate(expr).should eq -1.0
    #   end
    # end
  end
end
