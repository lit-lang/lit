require "./spec_helper"

describe Lit::Parser do
  it "parses an integer" do
    token = Lit::Parser.parse("1").first
    token.should be_a Lit::Token
    token.type.should eq Lit::TokenType::Number
    token.lexeme.should eq "1"
    token.literal.should eq 1
    token.line.should eq 1
  end

  it "parses a bigger integer" do
    token = Lit::Parser.parse("504").first
    token.should be_a Lit::Token
    token.type.should eq Lit::TokenType::Number
    token.lexeme.should eq "504"
    token.literal.should eq 504
    token.line.should eq 1
  end

  it "parses a float" do
    token = Lit::Parser.parse("69.420").first
    token.should be_a Lit::Token
    token.type.should eq Lit::TokenType::Number
    token.lexeme.should eq "69.420"
    token.literal.should eq 69.420
    token.line.should eq 1
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
