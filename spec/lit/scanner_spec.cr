require "../spec_helper"

describe Lit::Scanner do
  Spec.around_each do |example|
    ::Lit.with_current_file_path(__FILE__) do
      example.run
    end
  end

  ((0..10).to_a + [504, 69.420]).each do |n|
    it_scans n.to_s, to_type: token_type(NUMBER), to_literal: n
  end

  it_scans "", to_type: token_type(EOF)
  it_scans "\n", to_type: token_type(NEWLINE), at_line: 1
  it_scans ";", to_type: token_type(NEWLINE), at_line: 1
  it_scans "(", to_type: token_type(LEFT_PAREN)
  it_scans ")", to_type: token_type(RIGHT_PAREN)
  it_scans "[", to_type: token_type(LEFT_BRACKET)
  it_scans "]", to_type: token_type(RIGHT_BRACKET)
  it_scans "{", to_type: token_type(LEFT_BRACE)
  it_scans "}", to_type: token_type(RIGHT_BRACE)
  it_scans ",", to_type: token_type(COMMA)
  it_scans ".", to_type: token_type(DOT)
  it_scans ":", to_type: token_type(COLON)
  it_scans "!", to_type: token_type(BANG)
  it_scans "?", to_type: token_type(QUESTION)
  it_scans "+", to_type: token_type(PLUS)
  it_scans "-", to_type: token_type(MINUS)
  it_scans "/", to_type: token_type(SLASH)
  it_scans "*", to_type: token_type(STAR)
  it_scans "%", to_type: token_type(PERCENT)
  it_scans "+=", to_type: token_type(PLUS_EQUAL)
  it_scans "-=", to_type: token_type(MINUS_EQUAL)
  it_scans "*=", to_type: token_type(STAR_EQUAL)
  it_scans "/=", to_type: token_type(SLASH_EQUAL)
  it_scans "%=", to_type: token_type(PERCENT_EQUAL)
  it_scans "**", to_type: token_type(STAR_STAR)
  it_scans "=", to_type: token_type(EQUAL)
  it_scans "==", to_type: token_type(EQUAL_EQUAL)
  it_scans ">", to_type: token_type(GREATER)
  it_scans ">=", to_type: token_type(GREATER_EQUAL)
  it_scans "<", to_type: token_type(LESS)
  it_scans "<=", to_type: token_type(LESS_EQUAL)
  it_scans "|", to_type: token_type(BAR)
  it_scans "||", to_type: token_type(OR)
  it_scans "&.", to_type: token_type(AMPERSAND_DOT)
  it_scans "&&", to_type: token_type(AND)
  it_scans "|>", to_type: token_type(PIPE_GREATER)
  it_scans "!=", to_type: token_type(BANG_EQUAL)
  it_scans "silverchair!?", to_type: token_type(IDENTIFIER)
  it_scans ":hey", to_type: token_type(STRING), to_literal: "hey"

  it_scans_keywords

  it "scans strings" do
    str = %("This is a string. 1 + 1")

    token = Lit::Scanner.scan(str).first
    token.should be_a Lit::Token
    token.type.should eq token_type(STRING)
    token.lexeme.should eq str
    token.literal.should eq "This is a string. 1 + 1"
    token.line.should eq 1
  end

  it "scans strings with single quotes" do
    str = "'This is a string. 1 + 1'"

    token = Lit::Scanner.scan(str).first
    token.should be_a Lit::Token
    token.type.should eq token_type(STRING)
    token.lexeme.should eq str
    token.literal.should eq "This is a string. 1 + 1"
    token.line.should eq 1
  end

  it "scans multiline strings" do
    str = %("multi\nline\nstring")

    token = Lit::Scanner.scan(str).first
    token.should be_a Lit::Token
    token.type.should eq token_type(STRING)
    token.lexeme.should eq str
    token.literal.should eq "multi\nline\nstring"
    token.line.should eq 3
  end

  it "scans strings with escape sequences" do
    str = %("\\n \\t \\\\ \\' \\" \\y")

    token = Lit::Scanner.scan(str).first
    token.should be_a Lit::Token
    token.type.should eq token_type(STRING)
    token.lexeme.should eq str
    token.literal.should eq %(\n \t \\ ' " y)
    token.line.should eq 1
  end

  context "when encountering string interpolation" do
    it "scans string interpolation" do
      str = %("a {b} c {d}")

      tokens = Lit::Scanner.scan(str)

      tokens.size.should eq 6
      [tokens[0].type, tokens[0].literal].should eq [token_type(STRING_INTERPOLATION), "a "]
      [tokens[1].type, tokens[1].lexeme].should eq [token_type(IDENTIFIER), "b"]
      [tokens[2].type, tokens[2].literal].should eq [token_type(STRING_INTERPOLATION), " c "]
      [tokens[3].type, tokens[3].lexeme].should eq [token_type(IDENTIFIER), "d"]
      [tokens[4].type, tokens[4].literal].should eq [token_type(STRING), ""]
      tokens[5].type.should eq token_type(EOF)
    end
  end

  it "scans spaces" do
    token = Lit::Scanner.scan(" \r\t\r   1  \r\r\t      ").first
    token.should be_a Lit::Token
    token.type.should eq token_type(NUMBER)
    token.lexeme.should eq "1"
    token.literal.should eq 1
    token.line.should eq 1
  end

  context "when comment is found" do
    it "scans one-line comments" do
      tokens = Lit::Scanner.scan("# This is a comment.\n###### 1 + 1\n1")
      tokens.shift.type.should eq token_type(NEWLINE)
      tokens.shift.type.should eq token_type(NEWLINE)

      token = tokens[0]
      token.should be_a Lit::Token
      token.type.should eq token_type(NUMBER)
      token.lexeme.should eq "1"
      token.literal.should eq 1
      token.line.should eq 3
    end

    it "scans block comments" do
      tokens = Lit::Scanner.scan("#=\nThis\n2\nShould\nBe\nIgnored\n# Commentception\n= #\n=#\n1")
      tokens.shift.type.should eq token_type(NEWLINE)

      token = tokens[0]
      token.should be_a Lit::Token
      token.type.should eq token_type(NUMBER)
      token.lexeme.should eq "1"
      token.literal.should eq 1
      token.line.should eq 10
    end

    it "scans nested comments" do
      token = Lit::Scanner.scan("#=\n #=\n  Nested comments!\n =#\n=#1").first
      token.should be_a Lit::Token
      token.type.should eq token_type(NUMBER)
      token.lexeme.should eq "1"
      token.literal.should eq 1
      token.line.should eq 5
    end

    it "scans inlined block comments" do
      token = Lit::Scanner.scan("#=2=#1").first
      token.should be_a Lit::Token
      token.type.should eq token_type(NUMBER)
      token.lexeme.should eq "1"
      token.literal.should eq 1
      token.line.should eq 1
    end
  end

  it "scans new lines" do
    tokens = Lit::Scanner.scan("\n\n\n1")
    tokens.shift.type.should eq token_type(NEWLINE)
    tokens.shift.type.should eq token_type(NEWLINE)
    tokens.shift.type.should eq token_type(NEWLINE)

    token = tokens[0]
    token.should be_a Lit::Token
    token.type.should eq token_type(NUMBER)
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

    error.should contain("[scanner_spec.cr:2] Syntax error: Unterminated block comment")
  end

  it "errors on unterminated string" do
    output_of { Lit::Scanner.scan(%("Unterminated \nstring')) }.should contain("[scanner_spec.cr:2] Syntax error: Unterminated string")
  end

  it "errors on unterminated string escape" do
    output_of { Lit::Scanner.scan(%("Unterminated \\)) }.should contain("Unterminated string escape")
  end

  it "errors on single '&'" do
    output_of { Lit::Scanner.scan("&") }.should contain("[scanner_spec.cr:1] Syntax error: Unexpected character '&'")
  end

  it "errors on unexpected chars" do
    output_of { Lit::Scanner.scan("@") }.should contain("[scanner_spec.cr:1] Syntax error: Unexpected character '@'")
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
    it_scans keyword_name.to_s, to_type: token_type
  end
end
