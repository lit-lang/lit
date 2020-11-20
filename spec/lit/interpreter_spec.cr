require "../spec_helper"

describe Lit::Interpreter do
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

  describe "#visit_grouping_expr" do
    it "evaluates its internal expression" do
      expr = Create.expr(:grouping)

      interpreter.evaluate(expr).should eq 1.0
    end
  end

  describe "#visit_binary_expr" do
    it "interprets the binary expression" do
      expr = Create.expr(:binary)

      interpreter.evaluate(expr).should eq 2.0
    end

    context "when is an invalid operation" do
      it "raises an error" do
        plus = Create.token(:plus)
        string_literal = Create.expr(:literal, "a string")
        number = Create.expr(:literal, 1.0)

        expr = Create.expr(:binary, left: number, right: string_literal, operator: plus)

        expect_raises(Lit::RuntimeError, /Operands must be numbers/) do
          interpreter.evaluate(expr)
        end
      end
    end

    context "when is an unknown operation" do
      it "raises an error" do
        pipe_operator = Create.token(:pipe_operator)
        number1 = Create.expr(:literal)
        number2 = Create.expr(:literal)

        expr = Create.expr(:binary, left: number2, right: number1, operator: pipe_operator)

        expect_raises(Lit::RuntimeError, /Unknown binary operator/) do
          interpreter.evaluate(expr)
        end
      end
    end
  end
end
