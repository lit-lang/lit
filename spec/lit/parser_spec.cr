require "../spec_helper"

describe Lit::Parser do
  it_parses :false, to_literal: false
  it_parses :true, to_literal: true
  it_parses :nil, to_literal: nil
  it_parses :number, to_literal: 1.0
  it_parses :string, to_literal: "some text"

  describe "print statements" do
    it do
      tokens = Create.tokens(:print, :number_1, :semicolon, :eof)
      stmt = Lit::Parser.parse(tokens).first.as(Lit::Stmt::Print)

      stmt.expression.as(Lit::Expr::Literal).value.should eq 1
    end

    context "when semicolon is missing" do
      it "errors" do
        tokens = Create.tokens(:print, :number_1, :eof)

        output_of {
          Lit::Parser.parse(tokens)
        }.should contain("I was expecting a semicolon after the print expression")
      end
    end
  end

  describe "logical expression" do
    it "parses 'and' expressions" do
      tokens = Create.tokens(:number, :and, :number_2, :semicolon, :eof)
      expr = Lit::Parser.parse(tokens).first.as(Lit::Stmt::Expression).expression.as(Lit::Expr::Logical)

      expr.operator.type.and?.should be_true
      expr.left.as(Lit::Expr::Literal).value.should eq 1.0
      expr.right.as(Lit::Expr::Literal).value.should eq 2.0
    end

    it "parses 'or' expressions" do
      tokens = Create.tokens(:number, :or, :number_2, :semicolon, :eof)
      expr = Lit::Parser.parse(tokens).first.as(Lit::Stmt::Expression).expression.as(Lit::Expr::Logical)

      expr.operator.type.or?.should be_true
      expr.left.as(Lit::Expr::Literal).value.should eq 1.0
      expr.right.as(Lit::Expr::Literal).value.should eq 2.0
    end
  end

  describe "binary expression" do
    it "parses equalities" do
      tokens = Create.tokens(:number, :equal_equal, :number_2, :semicolon, :eof)
      expr = Lit::Parser.parse(tokens).first.as(Lit::Stmt::Expression).expression.as(Lit::Expr::Binary)

      expr.operator.type.equal_equal?.should be_true
      expr.left.as(Lit::Expr::Literal).value.should eq 1.0
      expr.right.as(Lit::Expr::Literal).value.should eq 2.0
    end

    it "parses comparissons" do
      tokens = Create.tokens(:number, :less, :number_2, :semicolon, :eof)
      expr = Lit::Parser.parse(tokens).first.as(Lit::Stmt::Expression).expression.as(Lit::Expr::Binary)

      expr.operator.type.less?.should be_true
      expr.left.as(Lit::Expr::Literal).value.should eq 1.0
      expr.right.as(Lit::Expr::Literal).value.should eq 2.0
    end

    it "parses factors" do
      tokens = Create.tokens(:number, :slash, :number, :semicolon, :eof)
      expr = Lit::Parser.parse(tokens).first.as(Lit::Stmt::Expression).expression.as(Lit::Expr::Binary)

      expr.operator.type.slash?.should be_true
      expr.left.as(Lit::Expr::Literal).value.should eq 1.0
      expr.right.as(Lit::Expr::Literal).value.should eq 1.0
    end

    it "parses terms" do
      tokens = Create.tokens(:number, :plus, :number, :semicolon, :eof)
      expr = Lit::Parser.parse(tokens).first.as(Lit::Stmt::Expression).expression.as(Lit::Expr::Binary)

      expr.operator.type.plus?.should be_true
      expr.left.as(Lit::Expr::Literal).value.should eq 1.0
      expr.right.as(Lit::Expr::Literal).value.should eq 1.0
    end

    # NOTE: This test depends on Debug.s_expr
    it "has correct precedence" do
      # 1 + (2 - 3 * 4) < 0 == true or true and false
      tokens = Create.tokens(
        :number_1, :plus, :left_paren, :number_2, :minus, :number_3, :star,
        :number_4, :right_paren, :less, :number_0, :equal_equal, :true, :or,
        :true, :and, :false, :semicolon, :eof
      )
      exprs = Lit::Parser.parse(tokens).map(&.as(Lit::Stmt::Expression).expression)
      s_expr = Lit::Debug.s_expr(exprs)

      s_expr.should eq "(or (== (< (+ 1.0 (group (- 2.0 (* 3.0 4.0)))) 0.0) true) (and true false))"
    end

    it "parses multiple expressions" do
      tokens = Create.tokens(:string, :plus, :number, :minus, :number, :semicolon, :eof)
      expr = Lit::Parser.parse(tokens).first.as(Lit::Stmt::Expression).expression.as(Lit::Expr::Binary)

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
      tokens = Create.tokens(:minus, :number, :semicolon, :eof)
      expr = Lit::Parser.parse(tokens).first.as(Lit::Stmt::Expression).expression.as(Lit::Expr::Unary)

      expr.operator.type.minus?.should be_true
      expr.right.as(Lit::Expr::Literal).value.should eq 1.0
    end
  end

  describe "grouping expression" do
    it "parses a grouping expression" do
      group = Create.tokens(:left_paren, :number, :right_paren, :semicolon, :eof)
      expr = Lit::Parser.parse(group).first.as(Lit::Stmt::Expression).expression.as(Lit::Expr::Grouping)

      expr.expression.as(Lit::Expr::Literal).value.should eq 1
    end

    context "when there's no expression inside parens" do
      it "errors" do
        group = Create.tokens(:left_paren, :right_paren, :semicolon, :eof)
        error_msg = output_of { Lit::Parser.parse(group) }

        error_msg.should contain("I was expecting an expression here.")
      end
    end

    context "when there's no closing paren" do
      it "errors" do
        group = Create.tokens(:left_paren, :number, :semicolon, :eof)
        error_msg = output_of { Lit::Parser.parse(group) }

        error_msg.should contain "I was expecting a ')' here."
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
    expr = Lit::Parser.parse(Create.tokens(type, :semicolon, :eof)).first.as(Lit::Stmt::Expression)
    expr.expression.as(Lit::Expr::Literal).value.should eq to_literal
  end
end
