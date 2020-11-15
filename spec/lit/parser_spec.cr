require "../spec_helper"

describe Lit::Parser do
  it_parses :false, to_literal: false
  it_parses :true, to_literal: true
  it_parses :nil, to_literal: nil
  it_parses :number, to_literal: 1.0
  it_parses :string, to_literal: "some text"

  context "when there's an unexpected token" do
    it "raises an error and outputs a message" do
      error_msg = output_of do
        expect_raises(Lit::Parser::ParserError) do
          Lit::Parser.parse([Create.token(:left_paren)])
        end
      end

      error_msg.should contain("[Line 1] Error at \"(\": I was expecting an expression here.")
    end
  end
end

private def it_parses(type : Symbol, to_literal)
  it "parses literal #{type}" do
    expr = Lit::Parser.parse([Create.token(type)])
    expr.value.should eq to_literal
  end
end
