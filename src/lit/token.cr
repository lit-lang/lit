require "./token_type"

module Lit
  class Token
    getter type : TokenType
    getter lexeme : String
    getter literal : Int64 | Float64 | String | Nil
    getter line : Int32

    def initialize(@type, @lexeme, @literal, @line); end

    def inspect
      %(<#{type} lexeme: #{lexeme.inspect} literal: #{literal ? literal.inspect : "nothing"}>)
    end

    def with_lexeme(lexeme)
      self.class.new(type, lexeme, literal, line)
    end

    delegate :to_s, to: :inspect
  end
end
