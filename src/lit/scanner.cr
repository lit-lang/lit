require "./token"
require "./keywords"
require "./lit"

module Lit
  class Scanner
    MAX_INTERPOLATION_DEPTH = 8

    def initialize(src : String, error_reporter : ErrorReporter)
      @error_reporter = error_reporter
      @tokens = [] of Token
      @src = src
      # Interpolated strings make the lexer not strictly regular: we don't know
      # whether a ")" should be treated as a RIGHT_PAREN token or as ending an
      # interpolated expression unless we know whether we are inside a string
      # interpolation and how many unmatched "(" there are. This is particularly
      # complex because interpolation can nest:
      #
      #     " { " { inner } " } "
      #
      # This tracks that state. The parser maintains a stack of ints, one for each
      # level of current interpolation nesting. Each value is the number of
      # unmatched "{" that are waiting to be closed.
      @braces = StaticArray(Int32, MAX_INTERPOLATION_DEPTH).new(0)
      @interpolation_depth = 0
      @token_start_pos = 0
      @current_pos = 0
      @line = 1
    end

    def self.scan(src : String) : Array(Token)
      new(src, ErrorReporter.new).scan
    end

    def scan
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
      when '['
        add_token(TokenType::LEFT_BRACKET)
      when ']'
        add_token(TokenType::RIGHT_BRACKET)
      when '{'
        add_token(TokenType::LEFT_BRACE)
      when '}'
        # If we are inside an interpolated expression, count the "}".
        if @interpolation_depth > 0 && (current_interpolation_braces - 1) == 0
          # This is the final "}", so the interpolation expression has ended.
          # This "}" now begins the next section of the template string.
          @interpolation_depth -= 1
          consume_string('"')
        else
          add_token(TokenType::RIGHT_BRACE)
        end
      when ','
        add_token(TokenType::COMMA)
      when '.'
        add_token(TokenType::DOT)
      when ':'
        alphanumeric?(peek) ? consume_symbol_string : add_token(TokenType::COLON)
      when ';'
        add_token(TokenType::NEWLINE)
      when '+'
        add_token(TokenType::PLUS)
      when '-'
        add_token(TokenType::MINUS)
      when '/'
        add_token(TokenType::SLASH)
      when '%'
        add_token(TokenType::PERCENT)
      when '?'
        add_token(TokenType::QUESTION)
      when '*'
        match?('*') ? add_token(TokenType::STAR_STAR) : add_token(TokenType::STAR)
      when '='
        match?('=') ? add_token(TokenType::EQUAL_EQUAL) : add_token(TokenType::EQUAL)
      when '>'
        match?('=') ? add_token(TokenType::GREATER_EQUAL) : add_token(TokenType::GREATER)
      when '<'
        match?('=') ? add_token(TokenType::LESS_EQUAL) : add_token(TokenType::LESS)
      when '!'
        match?('=') ? add_token(TokenType::BANG_EQUAL) : add_token(TokenType::BANG)
      when '|'
        if match?('|')
          add_token(TokenType::OR)
        elsif match?('>')
          add_token(TokenType::PIPE_GREATER)
        else
          add_token(TokenType::BAR)
        end
      when '&'
        if match?('&')
          add_token(TokenType::AND)
        else
          syntax_error("Unexpected character #{c.inspect}")
        end
      when '\n'
        @line += 1
        add_token(TokenType::NEWLINE)
      when '#'
        match?('=') ? consume_block_comment : consume_line_comment
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
          syntax_error("Unexpected character #{c.inspect}")
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
      successful = scan_digits_with_underscores
      return unless successful
      number = current_token_string.dup.delete('_').to_i64

      # the next character can't be a _ but I'm allowing it here to give it a
      # better error message inside `scan_digits_with_underscores`
      if peek == '.' && (digit?(peek_next) || peek_next == '_')
        advance # consuming the .
        successful = scan_digits_with_underscores
        return unless successful
        number = current_token_string.delete('_').to_f
      end

      if current_token_string.ends_with?("_")
        return syntax_error("Trailing underscore in number literal")
      end

      add_token(TokenType::NUMBER, number)
    end

    private def scan_digits_with_underscores
      while digit?(peek) || peek == '_'
        previous_char = peek_previous
        current_char = advance

        if current_char == '_'
          if !digit?(previous_char)
            syntax_error("Invalid underscore placement in number literal")
            return false
          end
        elsif !digit?(current_char)
          syntax_error("Unexpected character #{current_char.inspect}")
          return false
        end
      end

      if peek_previous == '_' && peek == '.'
        syntax_error("Invalid underscore placement in number literal")
        return false
      end

      true
    end

    private def consume_line_comment
      until peek == '\n' || at_end?
        advance
      end
    end

    private def consume_block_comment
      nesting = 1

      while nesting > 0
        return syntax_error("Unterminated block comment") if at_end?

        if closing_comment_next?
          nesting -= 1
          advance # consume the =
          advance # consume the #
          next
        end

        if opening_block_comment_next?
          nesting += 1
          advance # consume the #
          advance # consume the =
          next
        end

        # Regular comment char
        @line += 1 if peek == '\n'
        advance
      end
    end

    private def consume_string(quote) : Nil
      # TODO: use String.build
      string = ""
      token_type = TokenType::STRING

      loop do
        return syntax_error("Unterminated string.") if at_end?

        c = advance

        break if c == quote

        if quote == '"' # only double quotes support interpolation and escapes
          if c == '\\'
            return syntax_error("Unterminated string escape.") if at_end?

            e = advance

            case e
            when 'n'
              string += "\n"
            when 't'
              string += "\t"
            when 'r'
              string += "\r"
            else
              string += e # Adding the unknown escape sequence to the string
            end
          elsif c == '{'
            if @interpolation_depth >= MAX_INTERPOLATION_DEPTH
              syntax_error("Interpolation may only nest #{MAX_INTERPOLATION_DEPTH} levels deep.")
            else
              @braces[@interpolation_depth] = 1
              @interpolation_depth += 1
              token_type = TokenType::STRING_INTERPOLATION
              break
            end
          else
            @line += 1 if c == '\n'
            string += c # Normal character
          end
        else
          @line += 1 if c == '\n'
          string += c # Normal character
        end
      end

      add_token(token_type, string)
    end

    private def consume_symbol_string : Nil
      s = String.build do |str|
        while alphanumeric?(peek)
          str << advance
        end
      end

      add_token(TokenType::STRING, s)
    end

    private def consume_identifier
      while alphanumeric?(peek)
        advance
      end

      text = @src[@token_start_pos...@current_pos]
      type = keyword_from(text) || TokenType::IDENTIFIER

      add_token(type)
    end

    private def peek : Char
      return '\0' if at_end?

      @src[@current_pos]
    end

    private def peek_next : Char
      return '\0' if (@current_pos + 1) >= @src.size

      @src[@current_pos + 1]
    end

    private def peek_previous : Char
      return '\0' if @current_pos == 0

      @src[@current_pos - 1]
    end

    private def current_token_string
      @src[@token_start_pos...@current_pos]
    end

    private def current_interpolation_braces
      return 0 if @interpolation_depth == 0

      @braces[@interpolation_depth - 1]
    end

    private def add_token(type : TokenType)
      add_token(type, nil)
    end

    private def add_token(type, literal)
      # Make line tokens appear on the line containing the "\n".
      line = type == TokenType::NEWLINE ? @line - 1 : @line
      @tokens << Token.new(type, current_token_string, literal, line)
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
      alpha?(c) || digit?(c) || c.in?({'?', '!'})
    end

    private def keyword_from(text : String)
      KEYWORDS[text]?
    end

    private def closing_comment_next?
      peek == '=' && peek_next == '#'
    end

    private def opening_block_comment_next?
      peek == '#' && peek_next == '='
    end

    private def syntax_error(message : String)
      @error_reporter.report_syntax_error(@line, message)
      synchronize
    end

    # Avoid reporting unhelpful errors when scanner is in a bad state
    private def synchronize
      # TODO: Do we need to handle comments here?
      until peek == '\n' || peek == ';' || peek == ')' || peek == '}' || peek == ']' || at_end?
        advance
      end
    end
  end
end
