module Lit
  KEYWORDS = {
    and:    TokenType::AND,
    else:   TokenType::ELSE,
    false:  TokenType::FALSE,
    fn:     TokenType::FN,
    if:     TokenType::IF,
    is:     TokenType::EQUAL_EQUAL,
    let:    TokenType::LET,
    nil:    TokenType::NIL,
    not:    TokenType::BANG,
    or:     TokenType::OR,
    print:  TokenType::PRINT,
    puts:   TokenType::PRINT, # TODO: Handle print and puts correctly
    return: TokenType::RETURN,
    true:   TokenType::TRUE,
    while:  TokenType::WHILE,
  }
end
