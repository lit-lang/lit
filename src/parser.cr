require "./token"
require "./keywords"

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
      scan_tokens
      add_eof_token

      @tokens
    end

    private def scan_tokens
      until at_end?
        @token_start_pos = @current_pos
        scan_token
      end
    end

    private def at_end?
      @current_pos >= @src.size
    end

    private def scan_token
      c = advance

      case c
      when '('
        add_token(TokenType::LEFT_PAREN)
      when ')'
        add_token(TokenType::RIGHT_PAREN)
      when '{'
        add_token(TokenType::LEFT_BRACE)
      when '}'
        add_token(TokenType::RIGHT_BRACE)
      when ','
        add_token(TokenType::COMMA)
      when '.'
        add_token(TokenType::DOT)
      when ';'
        add_token(TokenType::SEMICOLON)
      when '+'
        add_token(TokenType::PLUS)
      when '-'
        add_token(TokenType::MINUS)
      when '/'
        add_token(TokenType::SLASH)
      when '*'
        match?('*') ? add_token(TokenType::STAR_STAR) : add_token(TokenType::STAR)
      when '='
        match?('=') ? add_token(TokenType::EQUAL_EQUAL) : add_token(TokenType::EQUAL)
      when '>'
        match?('=') ? add_token(TokenType::GREATER_EQUAL) : add_token(TokenType::GREATER)
      when '<'
        match?('=') ? add_token(TokenType::LESS_EQUAL) : add_token(TokenType::LESS)
      when '|'
        if match?('|')
          add_token(TokenType::BAR_BAR)
        elsif match?('>')
          add_token(TokenType::PIPE_OPERATOR)
        else
          add_token(TokenType::BAR)
        end
      when '\n'
        @line += 1
      when '#'
        consume_comment
      when ' ', '\r', '\t'
        # ignore whitespaces
      when '"', '\''
        consume_string(quote: c)
      else
        if digit?(c)
          consume_number
        elsif alpha?(c)
          consume_identifier
        else
          raise "Unexpected character #{c.inspect} at line #{@line}"
        end
      end
    end

    private def advance
      @current_pos += 1

      @src[@current_pos - 1]
    end

    private def match?(expected)
      return false if at_end?
      return false if @src[@current_pos] != expected

      @current_pos += 1

      true
    end

    private def consume_number
      while digit?(peek)
        advance
      end

      if peek == '.' && digit?(peek_next)
        advance # consuming the .

        while digit?(peek)
          advance
        end
      end

      add_token(TokenType::NUMBER, current_token_string.to_f)
    end

    private def consume_comment
      until peek == '\n' || at_end?
        advance
      end
    end

    private def consume_string(quote)
      until peek == quote || at_end?
        @line += 1 if peek == '\n'
        advance
      end

      raise "Unterminated string at line #{@line}" if at_end?

      advance # Consume the closing quote

      value = current_token_string.delete(quote)

      add_token(TokenType::STRING, value)
    end

    private def consume_identifier
      while alphanumeric?(peek)
        advance
      end

      text = @src[@token_start_pos...@current_pos]
      type = keyword?(text) ? TokenType::KEYWORD : TokenType::IDENTIFIER

      add_token(type)
    end

    private def peek : Char
      return '\0' if at_end?

      @src[@current_pos]
    end

    private def peek_next : Char
      return '\0' if (@current_pos + 1) > @src.size

      @src[@current_pos + 1]
    end

    private def current_token_string
      @src[@token_start_pos...@current_pos]
    end

    private def add_token(type : TokenType)
      add_token(type, nil)
    end

    private def add_token(type, literal)
      @tokens << Token.new(type, current_token_string, literal, @line)
    end

    private def add_eof_token
      @tokens << Token.new(TokenType::EOF, "", nil, @line)
    end

    private def digit?(c : Char) : Bool
      c.in? '0'..'9'
    end

    private def alpha?(c : Char) : Bool
      c.in?('a'..'z') || c.in?('A'..'Z') || c == '_'
    end

    private def alphanumeric?(c : Char) : Bool
      alpha?(c) || digit?(c) || c.in? ['?', '!']
    end

    private def keyword?(identifier : String) : Bool
      identifier.in? KEYWORDS
    end
  end
end
