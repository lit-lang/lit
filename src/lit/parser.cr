require "./token"
require "./token_type"
require "./expr"

module Lit
  class Parser
    class ParserError < Exception; end

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
      return Expr::Literal.new(nil) if match?(TokenType::NIL)
      return Expr::Literal.new(previous.literal) if match?(TokenType::NUMBER, TokenType::STRING)

      raise error(peek, "I was expecting an expression here.")
    end

    private def match?(*types) : Bool
      types.each do |type|
        if check(type)
          advance

          return true
        end
      end

      false
    end

    private def check(type : TokenType)
      peek.type == type
    end

    private def peek
      tokens[current]
    end

    private def previous
      tokens[current - 1]
    end

    private def advance
      @current += 1
    end

    private def error(token, msg)
      Lit.error(token, msg)

      ParserError.new
    end
  end
end
