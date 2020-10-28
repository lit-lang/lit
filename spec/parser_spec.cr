require "./spec_helper"

private def it_parses(str, to_type, to_literal)
  it "parses #{str}" do
    token = Lit::Parser.parse(str).first
    token.should be_a Lit::Token
    token.type.should eq to_type
    token.lexeme.should eq str
    token.literal.should eq to_literal
    token.line.should eq 1
  end
end

describe Lit::Parser do
  ((0..10).to_a + [504, 69.420]).each do |n|
    it_parses n.to_s, to_type: Lit::TokenType::Number, to_literal: n
  end

  it "parses nothing" do
    token = Lit::Parser.parse("").first
    token.should be_a Lit::Token
    token.type.should eq Lit::TokenType::EOF
    token.lexeme.should eq ""
    token.literal.should eq nil
    token.line.should eq 1
  end

  it "raises erros on unexpected chars" do
    expect_raises(Exception) do
      Lit::Parser.parse("a")
    end
  end
end
