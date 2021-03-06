require "./token_type"

module Lit
  class Token
    getter type : TokenType
    getter lexeme : String
    getter literal : Float64 | String | Nil
    getter line : Int32

    def initialize(@type, @lexeme, @literal, @line); end

    def inspect
      %(<#{type} '#{lexeme}'#{literal ? ": #{literal}" : ""}>)
    end

    delegate :to_s, to: :inspect
  end
end
