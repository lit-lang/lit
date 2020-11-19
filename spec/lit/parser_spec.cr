require "../spec_helper"

describe Lit::Parser do
  it_parses :false, to_literal: false
  it_parses :true, to_literal: true
  it_parses :nil, to_literal: nil
  it_parses :number, to_literal: 1.0
  it_parses :string, to_literal: "some text"

  describe "binary expression" do
    it "parses equalities" do
      tokens = Create.tokens(:number, :equal_equal, :number_2, :eof)
      expr = Lit::Parser.parse(tokens).first.as(Lit::Expr::Binary)

      expr.operator.type.equal_equal?.should be_true
      expr.left.as(Lit::Expr::Literal).value.should eq 1.0
      expr.right.as(Lit::Expr::Literal).value.should eq 2.0
    end

    it "parses comparissons" do
      tokens = Create.tokens(:number, :less, :number_2, :eof)
      expr = Lit::Parser.parse(tokens).first.as(Lit::Expr::Binary)

      expr.operator.type.less?.should be_true
      expr.left.as(Lit::Expr::Literal).value.should eq 1.0
      expr.right.as(Lit::Expr::Literal).value.should eq 2.0
    end

    it "parses factors" do
      tokens = Create.tokens(:number, :slash, :number, :eof)
      expr = Lit::Parser.parse(tokens).first.as(Lit::Expr::Binary)

      expr.operator.type.slash?.should be_true
      expr.left.as(Lit::Expr::Literal).value.should eq 1.0
      expr.right.as(Lit::Expr::Literal).value.should eq 1.0
    end

    it "parses terms" do
      tokens = Create.tokens(:number, :plus, :number, :eof)
      expr = Lit::Parser.parse(tokens).first.as(Lit::Expr::Binary)

      expr.operator.type.plus?.should be_true
      expr.left.as(Lit::Expr::Literal).value.should eq 1.0
      expr.right.as(Lit::Expr::Literal).value.should eq 1.0
    end

    # NOTE: This test depends on Debug.s_expr
    it "has correct precedence" do
      # 1 + (2 - 3 * 4) < 0 == true
      tokens = Create.tokens(
        :number_1, :plus, :left_paren, :number_2, :minus, :number_3, :star,
        :number_4, :right_paren, :less, :number_0, :equal_equal, :true, :eof
      )
      s_expr = Lit::Debug.s_expr(Lit::Parser.parse(tokens))
      s_expr.should eq "(== (< (+ 1.0 (group (- 2.0 (* 3.0 4.0)))) 0.0) true)"
    end

    it "parses multiple expressions" do
      tokens = Create.tokens(:string, :plus, :number, :minus, :number, :eof)
      expr = Lit::Parser.parse(tokens).first.as(Lit::Expr::Binary)

      expr.operator.type.minus?.should be_true

      left_expr = expr.left.as(Lit::Expr::Binary)
      left_expr.operator.type.plus?.should be_true
      left_expr.left.as(Lit::Expr::Literal).value.should eq "some text"
      left_expr.right.as(Lit::Expr::Literal).value.should eq 1.0

      expr.right.as(Lit::Expr::Literal).value.should eq 1.0
    end
  end

  describe "unary expression" do
    it "parses a unary expression" do
      tokens = Create.tokens(:minus, :number, :eof)
      expr = Lit::Parser.parse(tokens).first.as(Lit::Expr::Unary)

      expr.operator.type.minus?.should be_true
      expr.right.as(Lit::Expr::Literal).value.should eq 1.0
    end
  end

  describe "grouping expression" do
    it "parses a grouping expression" do
      group = Create.tokens(:left_paren, :number, :right_paren, :eof)
      expr = Lit::Parser.parse(group).first.as(Lit::Expr::Grouping)

      expr.expression.as(Lit::Expr::Literal).value.should eq 1
    end

    context "when there's no expression inside parens" do
      it "parses a grouping expression" do
        group = Create.tokens(:left_paren, :right_paren, :eof)
        error_msg = output_of { Lit::Parser.parse(group) }

        error_msg.should contain("[Line 1] Error at \")\": I was expecting an expression here.")
      end
    end

    context "when there's no closing paren" do
      it "parses a grouping expression" do
        group = Create.tokens(:left_paren, :number, :eof)
        error_msg = output_of { Lit::Parser.parse(group) }

        error_msg.should contain "[Line 1] Error at end: I was expecting a ')' here."
      end
    end
  end

  context "when there's an unexpected token" do
    it "outputs a message" do
      error_msg = output_of { Lit::Parser.parse(Create.tokens(:comma, :eof)) }

      error_msg.should contain("[Line 1] Error at \",\": I was expecting an expression here.")
    end
  end
end

private def it_parses(type : Symbol, to_literal)
  it "parses literal #{type}" do
    expr = Lit::Parser.parse(Create.tokens(type, :eof)).first.as(Lit::Expr::Literal)
    expr.value.should eq to_literal
  end
end
