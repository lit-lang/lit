require "./token"
require "./token_type"
require "./expr"

module Lit
  class Parser
    getter tokens : Array(Token)
    getter current : Int32 = 0

    def initialize(@tokens : Array(Token)); end

    def self.parse(tokens)
      new(tokens).parse
    end

    def parse : Expr
      primary
    end

    private def primary
      return Expr::Literal.new(false) if match?(TokenType::FALSE)
      return Expr::Literal.new(true) if match?(TokenType::TRUE)

      Expr::Literal.new(nil)
    end

    private def match?(type : TokenType)
      peek.type == type
    end

    private def peek
      tokens[current]
    end
  end
end
