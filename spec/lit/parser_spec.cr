require "../spec_helper"

describe Lit::Parser do
  it_parses :false, to_literal: false
  it_parses :true, to_literal: true
  it_parses :nil, to_literal: nil
  it_parses :number, to_literal: 1.0
  it_parses :string, to_literal: "some text"

  describe "let statements" do
    it "parses let statements" do
      tokens = Create.tokens(:let, :identifier, :semicolon, :eof)
      stmt = Lit::Parser.parse(tokens).first.as(Lit::Stmt::Let)

      stmt.name.lexeme.should eq "my_var"
      stmt.initializer.as(Lit::Expr::Literal).value.should eq nil
    end

    it "parses let statements with initializer" do
      tokens = Create.tokens(:let, :identifier, :equal, :number, :semicolon, :eof)
      stmt = Lit::Parser.parse(tokens).first.as(Lit::Stmt::Let)

      stmt.name.lexeme.should eq "my_var"
      stmt.initializer.as(Lit::Expr::Literal).value.should eq 1.0
    end

    context "when there's no variable name" do
      it do
        tokens = Create.tokens(:let, :semicolon, :eof)
        error_msg = output_of { Lit::Parser.parse(tokens) }

        error_msg.should contain("I was expecting a variable name here")
      end
    end

    context "when there's no semicolon after variable declaration" do
      it do
        tokens = Create.tokens(:let, :identifier, :eof)
        error_msg = output_of { Lit::Parser.parse(tokens) }

        error_msg.should contain("I was expecting a semicolon after variable declaration")
      end
    end
  end

  describe "println statements" do
    it "parses println statements" do
      tokens = Create.tokens(:println, :number_1, :semicolon, :eof)
      stmt = Lit::Parser.parse(tokens).first.as(Lit::Stmt::Println)

      stmt.expression.as(Lit::Expr::Literal).value.should eq 1
    end

    context "when semicolon is missing" do
      it "errors" do
        tokens = Create.tokens(:println, :number_1, :eof)

        output_of {
          Lit::Parser.parse(tokens)
        }.should contain("I was expecting a semicolon after the println statement")
      end
    end
  end

  describe "assignment expression" do
    it "parses the assignment" do
      tokens = Create.tokens(:identifier, :equal, :number, :semicolon, :eof)
      expr = Lit::Parser.parse(tokens).first.as(Lit::Stmt::Expression).expression.as(Lit::Expr::Assign)

      expr.name.type.identifier?.should be_true
      expr.name.lexeme.should eq "my_var"
      expr.value.as(Lit::Expr::Literal).value.should eq 1.0
    end

    context "when left hand is not a variable expression" do
      tokens = Create.tokens(:number, :equal, :number, :semicolon, :eof)

      output_of { Lit::Parser.parse(tokens) }.should contain("I was expecting a variable before the equal sign")
    end
  end

  describe "ternary expression" do
    it "parses the ternary" do
      tokens = Create.tokens(:true, :question, :number, :colon, :number_2, :semicolon, :eof)
      expr = Lit::Parser.parse(tokens).first.as(Lit::Stmt::Expression).expression.as(Lit::Expr::Ternary)

      expr.operator.type.question?.should be_true
      expr.left.as(Lit::Expr::Literal).value.should eq 1.0
      expr.right.as(Lit::Expr::Literal).value.should eq 2.0
    end

    context "when colon is missing" do
      tokens = Create.tokens(:true, :question, :number, :number_2, :semicolon, :eof)

      output_of { Lit::Parser.parse(tokens) }.should contain(
        "I was expecting a colon after the truthy condition on the ternary expression"
      )
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

    it "parses mod" do
      tokens = Create.tokens(:number, :percent, :number, :semicolon, :eof)
      expr = Lit::Parser.parse(tokens).first.as(Lit::Stmt::Expression).expression.as(Lit::Expr::Binary)

      expr.operator.type.percent?.should be_true
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
        tokens = Create.tokens(:left_paren, :number, :semicolon, :eof)
        error_msg = output_of { Lit::Parser.parse(tokens) }

        error_msg.should contain "I was expecting a ')' here."
      end
    end
  end

  it "parses variable expressions" do
    tokens = Create.tokens(:identifier, :semicolon, :eof)
    expr = Lit::Parser.parse(tokens).first.as(Lit::Stmt::Expression).expression.as(Lit::Expr::Variable)

    expr.name.lexeme.should eq "my_var"
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
