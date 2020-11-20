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
    context "when operator is +" do
      it "sums numbers" do
        expr = Create.expr(:binary)

        interpreter.evaluate(expr).should eq 2.0
      end

      it "sums strings" do
        string1 = Create.expr(:literal, "a")
        string2 = Create.expr(:literal, "b")
        expr = Create.expr(:binary, left: string1, right: string2)

        interpreter.evaluate(expr).should eq "ab"
      end
    end

    context "when operator is -" do
      it do
        minus = Create.token(:minus)
        expr = Create.expr(:binary, operator: minus)

        interpreter.evaluate(expr).should eq 0
      end
    end

    context "when operator is *" do
      it "multiplies numbers" do
        star = Create.token(:star)
        number_2 = Create.expr(:literal, 2.0)
        expr = Create.expr(:binary, operator: star, left: number_2, right: number_2)

        interpreter.evaluate(expr).should eq 4.0
      end
    end

    context "when operator is /" do
      it "multiplies numbers" do
        slash = Create.token(:slash)
        number_2 = Create.expr(:literal, 2.0)
        expr = Create.expr(:binary, operator: slash, left: number_2, right: number_2)

        interpreter.evaluate(expr).should eq 1.0
      end
    end

    context "when operator is ==" do
      it "compares equal values" do
        equal_equal = Create.token(:equal_equal)
        number_2 = Create.expr(:literal, 2.0)
        expr = Create.expr(:binary, operator: equal_equal, left: number_2, right: number_2)

        interpreter.evaluate(expr).should be_true
      end

      it "compares different values" do
        equal_equal = Create.token(:equal_equal)
        number_1 = Create.expr(:literal, 1.0)
        number_2 = Create.expr(:literal, 2.0)
        expr = Create.expr(:binary, operator: equal_equal, left: number_1, right: number_2)

        interpreter.evaluate(expr).should be_false
      end
    end

    context "when operator is !=" do
      it "compares equal values" do
        bang_equal = Create.token(:bang_equal)
        number_2 = Create.expr(:literal, 2.0)
        expr = Create.expr(:binary, operator: bang_equal, left: number_2, right: number_2)

        interpreter.evaluate(expr).should be_false
      end

      it "compares different values" do
        bang_equal = Create.token(:bang_equal)
        number_1 = Create.expr(:literal, 1.0)
        number_2 = Create.expr(:literal, 2.0)
        expr = Create.expr(:binary, operator: bang_equal, left: number_1, right: number_2)

        interpreter.evaluate(expr).should be_true
      end
    end

    context "when is an invalid operation" do
      it "raises an error" do
        plus = Create.token(:plus)
        string_literal = Create.expr(:literal, "a string")
        number = Create.expr(:literal, 1.0)

        expr = Create.expr(:binary, left: number, right: string_literal, operator: plus)

        expect_raises(Lit::RuntimeError, /Operands must be two numbers or two strings/) do
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
