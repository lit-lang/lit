require "./spec_helper"

private def it_parses(str, to_type, to_literal = nil)
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
    it_parses n.to_s, to_type: Lit::TokenType::NUMBER, to_literal: n
  end

  it_parses "", to_type: Lit::TokenType::EOF
  it_parses "(", to_type: Lit::TokenType::LEFT_PAREN
  it_parses ")", to_type: Lit::TokenType::RIGHT_PAREN
  it_parses "{", to_type: Lit::TokenType::LEFT_BRACE
  it_parses "}", to_type: Lit::TokenType::RIGHT_BRACE
  it_parses ",", to_type: Lit::TokenType::COMMA
  it_parses ".", to_type: Lit::TokenType::DOT
  it_parses ";", to_type: Lit::TokenType::SEMICOLON
  it_parses "+", to_type: Lit::TokenType::PLUS
  it_parses "-", to_type: Lit::TokenType::MINUS
  it_parses "/", to_type: Lit::TokenType::SLASH
  it_parses "*", to_type: Lit::TokenType::STAR
  it_parses "**", to_type: Lit::TokenType::STAR_STAR
  it_parses "=", to_type: Lit::TokenType::EQUAL
  it_parses "==", to_type: Lit::TokenType::EQUAL_EQUAL
  it_parses ">", to_type: Lit::TokenType::GREATER
  it_parses ">=", to_type: Lit::TokenType::GREATER_EQUAL
  it_parses "<", to_type: Lit::TokenType::LESS
  it_parses "<=", to_type: Lit::TokenType::LESS_EQUAL
  it_parses "|", to_type: Lit::TokenType::BAR
  it_parses "||", to_type: Lit::TokenType::BAR_BAR
  it_parses "|>", to_type: Lit::TokenType::PIPE_OPERATOR

  it "parses strings" do
    str = %("This is a string. 1 + 1")

    token = Lit::Parser.parse(str).first
    token.should be_a Lit::Token
    token.type.should eq Lit::TokenType::STRING
    token.lexeme.should eq str
    token.literal.should eq "This is a string. 1 + 1"
    token.line.should eq 1
  end

  it "parses multiline strings" do
    str = %("multi\nline\nstring")

    token = Lit::Parser.parse(str).first
    token.should be_a Lit::Token
    token.type.should eq Lit::TokenType::STRING
    token.lexeme.should eq str
    token.literal.should eq "multi\nline\nstring"
    token.line.should eq 3
  end

  it "parses spaces" do
    token = Lit::Parser.parse(" \r\t\r   1  \r\r\t      ").first
    token.should be_a Lit::Token
    token.type.should eq Lit::TokenType::NUMBER
    token.lexeme.should eq "1"
    token.literal.should eq 1
    token.line.should eq 1
  end

  it "parses comments" do
    token = Lit::Parser.parse("# This is a comment.\n###### 1 + 1\n1").first
    token.should be_a Lit::Token
    token.type.should eq Lit::TokenType::NUMBER
    token.lexeme.should eq "1"
    token.literal.should eq 1
    token.line.should eq 3
  end

  it "parses new lines" do
    token = Lit::Parser.parse("\n\n\n1").first
    token.should be_a Lit::Token
    token.type.should eq Lit::TokenType::NUMBER
    token.lexeme.should eq "1"
    token.literal.should eq 1
    token.line.should eq 4
  end

  it "parses tokens correctly" do
    Lit::Parser.parse("({12.13})").map(&.type.to_s).should eq(%w[
      LEFT_PAREN LEFT_BRACE NUMBER RIGHT_BRACE RIGHT_PAREN EOF
    ])
  end

  it "raises error on unexpected chars" do
    expect_raises(Exception, "Unexpected character 'a' at line 1") do
      Lit::Parser.parse("a")
    end
  end
end
