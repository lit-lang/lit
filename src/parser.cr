require "./token"

module Lit
  class Parser
    def initialize(src : String)
      @tokens = [] of Token
      @src = src
      @token_start_pos = 0
      @current_pos = 0
      @line = 1
    end

    def self.parse(src : String) : Array(Token)
      new(src).parse
    end

    def parse
      until at_end?
        @token_start_pos = @current_pos
        scan_token
      end

      @tokens
    end

    private def at_end?
      @current_pos >= @src.size
    end

    private def scan_token
      c = advance

      case c
      else
        if digit?(c)
          consume_number
        else
          add_token(TokenType::Nil)
        end
      end
    end

    private def advance
      @current_pos += 1

      @src[@current_pos - 1]
    end

    private def consume_number
      while digit?(peek); advance; end

      if peek == '.' && digit?(peek_next)
        advance # consuming the .

        while digit?(peek); advance; end
      end

      add_token(TokenType::Number, token_string.to_f)
    end

    private def peek : Char
      return '\0' if at_end?

      @src[@current_pos]
    end

    private def peek_next : Char
      return '\0' if (@current_pos + 1) > @src.size

      @src[@current_pos + 1]
    end

    private def token_string
      @src[@token_start_pos...@current_pos]
    end
    # private def current_char
    #   @src[@current_pos]
    # end

    private def add_token(type : TokenType)
      add_token(type, nil)
    end

    private def add_token(type, literal)
      text = @src[@token_start_pos...@current_pos]

      @tokens << Token.new(type, text, literal, @line)
    end

    private def digit?(c : Char) : Bool
      c.in? '0'..'9'
    end
  end
end