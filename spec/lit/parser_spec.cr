require "../spec_helper"

describe Lit::Parser do
  it_parses :false, to_literal: false
  it_parses :true, to_literal: true
  it_parses :nil, to_literal: nil
  it_parses :number, to_literal: 1.0
  it_parses :string, to_literal: "some text"

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
    expr = Lit::Parser.parse([Create.token(type), Create.token(:eof)]).first.as(Lit::Expr::Literal)
    expr.value.should eq to_literal
  end
end
