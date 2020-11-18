require "../spec_helper"

describe Lit::Scanner do
  ((0..10).to_a + [504, 69.420]).each do |n|
    it_scans n.to_s, to_type: token(NUMBER), to_literal: n
  end

  it_scans "", to_type: token(EOF)
  it_scans "\n", to_type: token(EOF), to_lexeme: "", at_line: 2
  it_scans "(", to_type: token(LEFT_PAREN)
  it_scans ")", to_type: token(RIGHT_PAREN)
  it_scans "[", to_type: token(LEFT_BRACKET)
  it_scans "]", to_type: token(RIGHT_BRACKET)
  it_scans "{", to_type: token(LEFT_BRACE)
  it_scans "}", to_type: token(RIGHT_BRACE)
  it_scans ",", to_type: token(COMMA)
  it_scans ".", to_type: token(DOT)
  it_scans ";", to_type: token(SEMICOLON)
  it_scans "+", to_type: token(PLUS)
  it_scans "-", to_type: token(MINUS)
  it_scans "/", to_type: token(SLASH)
  it_scans "*", to_type: token(STAR)
  it_scans "**", to_type: token(STAR_STAR)
  it_scans "=", to_type: token(EQUAL)
  it_scans "==", to_type: token(EQUAL_EQUAL)
  it_scans ">", to_type: token(GREATER)
  it_scans ">=", to_type: token(GREATER_EQUAL)
  it_scans "<", to_type: token(LESS)
  it_scans "<=", to_type: token(LESS_EQUAL)
  it_scans "|", to_type: token(BAR)
  it_scans "||", to_type: token(BAR_BAR)
  it_scans "|>", to_type: token(PIPE_OPERATOR)
  it_scans "->", to_type: token(ARROW)
  it_scans "!", to_type: token(BANG)
  it_scans "!=", to_type: token(BANG_EQUAL)
  it_scans "silverchair!?", to_type: token(IDENTIFIER)

  it_scans_keywords

  it "scans strings" do
    str = %("This is a string. 1 + 1")

    token = Lit::Scanner.scan(str).first
    token.should be_a Lit::Token
    token.type.should eq token(STRING)
    token.lexeme.should eq str
    token.literal.should eq "This is a string. 1 + 1"
    token.line.should eq 1
  end

  it "scans strings with single quotes" do
    str = "'This is a string. 1 + 1'"

    token = Lit::Scanner.scan(str).first
    token.should be_a Lit::Token
    token.type.should eq token(STRING)
    token.lexeme.should eq str
    token.literal.should eq "This is a string. 1 + 1"
    token.line.should eq 1
  end

  it "scans multiline strings" do
    str = %("multi\nline\nstring")

    token = Lit::Scanner.scan(str).first
    token.should be_a Lit::Token
    token.type.should eq token(STRING)
    token.lexeme.should eq str
    token.literal.should eq "multi\nline\nstring"
    token.line.should eq 3
  end

  it "scans spaces" do
    token = Lit::Scanner.scan(" \r\t\r   1  \r\r\t      ").first
    token.should be_a Lit::Token
    token.type.should eq token(NUMBER)
    token.lexeme.should eq "1"
    token.literal.should eq 1
    token.line.should eq 1
  end

  it "scans one-line comments" do
    token = Lit::Scanner.scan("# This is a comment.\n###### 1 + 1\n1").first
    token.should be_a Lit::Token
    token.type.should eq token(NUMBER)
    token.lexeme.should eq "1"
    token.literal.should eq 1
    token.line.should eq 3
  end

  it "scans block comments" do
    token = Lit::Scanner.scan("#=\nThis\n2\nShould\nBe\nIgnored\n# Commentception\n= #\n=#\n1").first
    token.should be_a Lit::Token
    token.type.should eq token(NUMBER)
    token.lexeme.should eq "1"
    token.literal.should eq 1
    token.line.should eq 10
  end

  it "scans inlined block comments" do
    token = Lit::Scanner.scan("#=2=#1").first
    token.should be_a Lit::Token
    token.type.should eq token(NUMBER)
    token.lexeme.should eq "1"
    token.literal.should eq 1
    token.line.should eq 1
  end

  it "scans new lines" do
    token = Lit::Scanner.scan("\n\n\n1").first
    token.should be_a Lit::Token
    token.type.should eq token(NUMBER)
    token.lexeme.should eq "1"
    token.literal.should eq 1
    token.line.should eq 4
  end

  it "scans tokens correctly" do
    Lit::Scanner.scan("({12.13})").map(&.type.to_s).should eq(%w[
      LEFT_PAREN LEFT_BRACE NUMBER RIGHT_BRACE RIGHT_PAREN EOF
    ])
  end

  it "errors on unterminated comment" do
    error = output_of { Lit::Scanner.scan("#=Unterminated\ncomment#") }

    error.should contain("[Line 2] Error: Unterminated block comment")
  end

  it "errors on unterminated string" do
    output_of { Lit::Scanner.scan(%("Unterminated \nstring')) }.should contain("[Line 2] Error: Unterminated string")
  end

  it "errors on unexpected chars" do
    output_of { Lit::Scanner.scan("?") }.should contain("[Line 1] Error: Unexpected character '?'")
  end
end

private def it_scans(str, to_type, to_literal = nil, to_lexeme = str, at_line = 1)
  it "scans #{str.inspect}" do
    token = Lit::Scanner.scan(str).first
    token.should be_a Lit::Token
    token.type.should eq to_type
    token.lexeme.should eq to_lexeme
    token.literal.should eq to_literal
    token.line.should eq at_line
  end
end

private def it_scans_keywords
  Lit::KEYWORDS.each do |keyword_name, token_type|
    it_scans keyword_name, to_type: token_type
  end
end
