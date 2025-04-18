module Lit
  enum TokenType
    LEFT_PAREN; RIGHT_PAREN; LEFT_BRACKET; RIGHT_BRACKET; LEFT_BRACE; RIGHT_BRACE

    COMMA; DOT; COLON; NEWLINE

    # Math
    PLUS; MINUS; SLASH; STAR; STAR_STAR; PERCENT

    # Comparison
    EQUAL; EQUAL_EQUAL; GREATER; GREATER_EQUAL; LESS; LESS_EQUAL

    BAR; BANG; BANG_EQUAL; QUESTION
    PIPE_GREATER

    # Literals
    NUMBER; STRING; IDENTIFIER; STRING_INTERPOLATION

    # Keywords
    AND; ELSE; FALSE; FN; IF; VAR; LET; NIL; OR; PRINT; PRINTLN; RETURN; TRUE; TYPE; SELF; WHILE; UNTIL; LOOP; BREAK; NEXT

    EOF
  end
end
