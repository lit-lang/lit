module Lit
  enum TokenType
    LEFT_PAREN; RIGHT_PAREN; LEFT_BRACE; RIGHT_BRACE
    COMMA; DOT; SEMICOLON
    PLUS; MINUS; SLASH; STAR; STAR_STAR
    EQUAL; EQUAL_EQUAL; GREATER; GREATER_EQUAL; LESS; LESS_EQUAL
    BAR; BAR_BAR
    PIPE_OPERATOR

    NUMBER; STRING; IDENTIFIER; KEYWORD
    EOF
  end
end
