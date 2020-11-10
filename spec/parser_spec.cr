require "./spec_helper"

private def it_scans(str, to_type, to_literal = nil)
  it "scans #{str}" do
    token = Lit::Scanner.scan(str).first
    token.should be_a Lit::Token
    token.type.should eq to_type
    token.lexeme.should eq str
    token.literal.should eq to_literal
    token.line.should eq 1
  end
end

describe Lit::Scanner do
  ((0..10).to_a + [504, 69.420]).each do |n|
    it_scans n.to_s, to_type: Lit::TokenType::NUMBER, to_literal: n
  end

  it_scans "", to_type: Lit::TokenType::EOF
  it_scans "(", to_type: Lit::TokenType::LEFT_PAREN
  it_scans ")", to_type: Lit::TokenType::RIGHT_PAREN
  it_scans "[", to_type: Lit::TokenType::LEFT_BRACKET
  it_scans "]", to_type: Lit::TokenType::RIGHT_BRACKET
  it_scans "{", to_type: Lit::TokenType::LEFT_BRACE
  it_scans "}", to_type: Lit::TokenType::RIGHT_BRACE
  it_scans ",", to_type: Lit::TokenType::COMMA
  it_scans ".", to_type: Lit::TokenType::DOT
  it_scans ";", to_type: Lit::TokenType::SEMICOLON
  it_scans "+", to_type: Lit::TokenType::PLUS
  it_scans "-", to_type: Lit::TokenType::MINUS
  it_scans "/", to_type: Lit::TokenType::SLASH
  it_scans "*", to_type: Lit::TokenType::STAR
  it_scans "**", to_type: Lit::TokenType::STAR_STAR
  it_scans "=", to_type: Lit::TokenType::EQUAL
  it_scans "==", to_type: Lit::TokenType::EQUAL_EQUAL
  it_scans ">", to_type: Lit::TokenType::GREATER
  it_scans ">=", to_type: Lit::TokenType::GREATER_EQUAL
  it_scans "<", to_type: Lit::TokenType::LESS
  it_scans "<=", to_type: Lit::TokenType::LESS_EQUAL
  it_scans "|", to_type: Lit::TokenType::BAR
  it_scans "||", to_type: Lit::TokenType::BAR_BAR
  it_scans "|>", to_type: Lit::TokenType::PIPE_OPERATOR
  it_scans "->", to_type: Lit::TokenType::ARROW
  it_scans "!", to_type: Lit::TokenType::BANG
  it_scans "!=", to_type: Lit::TokenType::BANG_EQUAL
  it_scans "silverchair!?", to_type: Lit::TokenType::IDENTIFIER
  it_scans "if", to_type: Lit::TokenType::KEYWORD

  it "scans strings" do
    str = %("This is a string. 1 + 1")

    token = Lit::Scanner.scan(str).first
    token.should be_a Lit::Token
    token.type.should eq Lit::TokenType::STRING
    token.lexeme.should eq str
    token.literal.should eq "This is a string. 1 + 1"
    token.line.should eq 1
  end

  it "scans strings with single quotes" do
    str = "'This is a string. 1 + 1'"

    token = Lit::Scanner.scan(str).first
    token.should be_a Lit::Token
    token.type.should eq Lit::TokenType::STRING
    token.lexeme.should eq str
    token.literal.should eq "This is a string. 1 + 1"
    token.line.should eq 1
  end

  it "scans multiline strings" do
    str = %("multi\nline\nstring")

    token = Lit::Scanner.scan(str).first
    token.should be_a Lit::Token
    token.type.should eq Lit::TokenType::STRING
    token.lexeme.should eq str
    token.literal.should eq "multi\nline\nstring"
    token.line.should eq 3
  end

  it "scans spaces" do
    token = Lit::Scanner.scan(" \r\t\r   1  \r\r\t      ").first
    token.should be_a Lit::Token
    token.type.should eq Lit::TokenType::NUMBER
    token.lexeme.should eq "1"
    token.literal.should eq 1
    token.line.should eq 1
  end

  it "scans comments" do
    token = Lit::Scanner.scan("# This is a comment.\n###### 1 + 1\n1").first
    token.should be_a Lit::Token
    token.type.should eq Lit::TokenType::NUMBER
    token.lexeme.should eq "1"
    token.literal.should eq 1
    token.line.should eq 3
  end

  it "scans new lines" do
    token = Lit::Scanner.scan("\n\n\n1").first
    token.should be_a Lit::Token
    token.type.should eq Lit::TokenType::NUMBER
    token.lexeme.should eq "1"
    token.literal.should eq 1
    token.line.should eq 4
  end

  it "scans tokens correctly" do
    Lit::Scanner.scan("({12.13})").map(&.type.to_s).should eq(%w[
      LEFT_PAREN LEFT_BRACE NUMBER RIGHT_BRACE RIGHT_PAREN EOF
    ])
  end

  it "raises error on unterminated string" do
    expect_raises(Exception, "Unterminated string at line 2") do
      Lit::Scanner.scan(%("Unterminated \nstring'))
    end
  end

  it "raises error on unexpected chars" do
    expect_raises(Exception, "Unexpected character '?' at line 1") do
      Lit::Scanner.scan("?")
    end
  end
end
