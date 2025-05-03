require "../spec_helper"

describe Lit::Parser do
  it_parses :false, to_literal: false
  it_parses :true, to_literal: true
  it_parses :nil, to_literal: nil
  it_parses :number, to_literal: 1.0
  it_parses :string, to_literal: "some text"

  describe "var statements" do
    it "parses var statements" do
      tokens = Create.tokens(:var, :identifier, :newline, :eof)
      stmt = Lit::Parser.parse(tokens).first.as(Lit::Stmt::Var)

      stmt.name.lexeme.should eq "my_var"
      stmt.mutable?.should be_true
      stmt.initializer.as(Lit::Expr::Literal).value.should eq nil
    end

    it "parses let statements" do
      tokens = Create.tokens(:let, :identifier, :newline, :eof)
      stmt = Lit::Parser.parse(tokens).first.as(Lit::Stmt::Var)

      stmt.name.lexeme.should eq "my_var"
      stmt.mutable?.should be_false
      stmt.initializer.as(Lit::Expr::Literal).value.should eq nil
    end

    it "parses var statements with initializer" do
      tokens = Create.tokens(:var, :identifier, :equal, :number, :newline, :eof)
      stmt = Lit::Parser.parse(tokens).first.as(Lit::Stmt::Var)

      stmt.name.lexeme.should eq "my_var"
      stmt.initializer.as(Lit::Expr::Literal).value.should eq 1.0
    end

    context "when there's no variable name" do
      it do
        tokens = Create.tokens(:var, :newline, :eof)
        error_msg = output_of { Lit::Parser.parse(tokens) }

        error_msg.should contain("I was expecting a variable name here")
      end
    end
  end

  describe "assignment expression" do
    it "parses the assignment" do
      tokens = Create.tokens(:identifier, :equal, :number, :newline, :eof)
      expr = Lit::Parser.parse(tokens).first.as(Lit::Stmt::Expression).expression.as(Lit::Expr::Assign)

      expr.name.type.identifier?.should be_true
      expr.name.lexeme.should eq "my_var"
      expr.value.as(Lit::Expr::Literal).value.should eq 1.0
    end

    context "when left hand is not a variable expression" do
      it "errors" do
        tokens = Create.tokens(:number, :equal, :number, :newline, :eof)

        output_of { Lit::Parser.parse(tokens) }.should contain("Invalid assignment target")
      end
    end
  end

  describe "logical expression" do
    it "parses 'and' expressions" do
      tokens = Create.tokens(:number, :and, :number_2, :newline, :eof)
      expr = Lit::Parser.parse(tokens).first.as(Lit::Stmt::Expression).expression.as(Lit::Expr::Logical)

      expr.operator.type.and?.should be_true
      expr.left.as(Lit::Expr::Literal).value.should eq 1.0
      expr.right.as(Lit::Expr::Literal).value.should eq 2.0
    end

    it "parses 'or' expressions" do
      tokens = Create.tokens(:number, :or, :number_2, :newline, :eof)
      expr = Lit::Parser.parse(tokens).first.as(Lit::Stmt::Expression).expression.as(Lit::Expr::Logical)

      expr.operator.type.or?.should be_true
      expr.left.as(Lit::Expr::Literal).value.should eq 1.0
      expr.right.as(Lit::Expr::Literal).value.should eq 2.0
    end
  end

  describe "binary expression" do
    it "parses equalities" do
      tokens = Create.tokens(:number, :equal_equal, :number_2, :newline, :eof)
      expr = Lit::Parser.parse(tokens).first.as(Lit::Stmt::Expression).expression.as(Lit::Expr::Binary)

      expr.operator.type.equal_equal?.should be_true
      expr.left.as(Lit::Expr::Literal).value.should eq 1.0
      expr.right.as(Lit::Expr::Literal).value.should eq 2.0
    end

    it "parses comparissons" do
      tokens = Create.tokens(:number, :less, :number_2, :newline, :eof)
      expr = Lit::Parser.parse(tokens).first.as(Lit::Stmt::Expression).expression.as(Lit::Expr::Binary)

      expr.operator.type.less?.should be_true
      expr.left.as(Lit::Expr::Literal).value.should eq 1.0
      expr.right.as(Lit::Expr::Literal).value.should eq 2.0
    end

    it "parses factors" do
      tokens = Create.tokens(:number, :slash, :number, :newline, :eof)
      expr = Lit::Parser.parse(tokens).first.as(Lit::Stmt::Expression).expression.as(Lit::Expr::Binary)

      expr.operator.type.slash?.should be_true
      expr.left.as(Lit::Expr::Literal).value.should eq 1.0
      expr.right.as(Lit::Expr::Literal).value.should eq 1.0
    end

    it "parses mod" do
      tokens = Create.tokens(:number, :percent, :number, :newline, :eof)
      expr = Lit::Parser.parse(tokens).first.as(Lit::Stmt::Expression).expression.as(Lit::Expr::Binary)

      expr.operator.type.percent?.should be_true
      expr.left.as(Lit::Expr::Literal).value.should eq 1.0
      expr.right.as(Lit::Expr::Literal).value.should eq 1.0
    end

    it "parses terms" do
      tokens = Create.tokens(:number, :plus, :number, :newline, :eof)
      expr = Lit::Parser.parse(tokens).first.as(Lit::Stmt::Expression).expression.as(Lit::Expr::Binary)

      expr.operator.type.plus?.should be_true
      expr.left.as(Lit::Expr::Literal).value.should eq 1.0
      expr.right.as(Lit::Expr::Literal).value.should eq 1.0
    end

    it "parses multiple expressions" do
      tokens = Create.tokens(:string, :plus, :number, :minus, :number, :newline, :eof)
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
      tokens = Create.tokens(:minus, :number, :newline, :eof)
      expr = Lit::Parser.parse(tokens).first.as(Lit::Stmt::Expression).expression.as(Lit::Expr::Unary)

      expr.operator.type.minus?.should be_true
      expr.right.as(Lit::Expr::Literal).value.should eq 1.0
    end
  end

  describe "grouping expression" do
    it "parses a grouping expression" do
      group = Create.tokens(:left_paren, :number, :right_paren, :newline, :eof)
      expr = Lit::Parser.parse(group).first.as(Lit::Stmt::Expression).expression.as(Lit::Expr::Grouping)

      expr.expression.as(Lit::Expr::Literal).value.should eq 1
    end

    context "when there's no expression inside parens" do
      it "errors" do
        group = Create.tokens(:left_paren, :right_paren, :newline, :eof)
        error_msg = output_of { Lit::Parser.parse(group) }

        error_msg.should contain("I was expecting an expression here.")
      end
    end

    context "when there's no closing paren" do
      it "errors" do
        tokens = Create.tokens(:left_paren, :number, :newline, :eof)
        error_msg = output_of { Lit::Parser.parse(tokens) }

        error_msg.should contain "I was expecting a ')' here."
      end
    end
  end

  it "parses variable expressions" do
    tokens = Create.tokens(:identifier, :newline, :eof)
    expr = Lit::Parser.parse(tokens).first.as(Lit::Stmt::Expression).expression.as(Lit::Expr::Variable)

    expr.name.lexeme.should eq "my_var"
  end

  describe "string interpolation" do
    it "parses string interpolation" do
      tokens = Create.tokens(:string_interpolation, :number, :string, :newline, :eof)
      expr = Lit::Parser.parse(tokens).first.as(Lit::Stmt::Expression).expression.as(Lit::Expr::StringInterpolation)

      expr.parts.size.should eq 3
      expr.token.should eq tokens.first
    end
  end

  context "when there's an unexpected token" do
    it "outputs a message" do
      error_msg = output_of { Lit::Parser.parse(Create.tokens(:comma, :eof)) }

      error_msg.should contain("[line 1] Error at \",\": I was expecting an expression here.")
    end
  end
end

private def it_parses(type : Symbol, to_literal)
  it "parses literal #{type}" do
    expr = Lit::Parser.parse(Create.tokens(type, :newline, :eof)).first.as(Lit::Stmt::Expression)
    expr.expression.as(Lit::Expr::Literal).value.should eq to_literal
  end
end
