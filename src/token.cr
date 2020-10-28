require "./token_type"

module Lit
  class Token
    getter type : TokenType
    getter lexeme : String
    getter literal : Float64?
    getter line : Int32

    def initialize(@type, @lexeme, @literal, @line); end

    def inspect
      "<#{type} '#{lexeme}': #{literal}>"
    end

    delegate :to_s, to: :inspect
  end
end