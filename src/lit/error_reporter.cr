module Lit
  class ErrorReporter
    private getter syntax_errors = [] of String
    private property runtime_error : String? = nil

    def add_syntax_error(line : Int, message : String)
      report(line, "", message)
    end

    def add_syntax_error(token : Token, message : String)
      report(token.line, syntax_error_location(token), message)
    end

    def add_runtime_error(error)
      self.runtime_error = Text.error("[line #{error.token.line}] Runtime error: #{error.message}").tap do |error|
        STDERR.puts error
      end
    end

    def had_syntax_error? : Bool
      !syntax_errors.empty?
    end

    def had_runtime_error? : Bool
      !!runtime_error
    end

    private def syntax_error_location(token : Token) : String
      if token.type.eof?
        " at end"
      elsif token.type.newline?
        " at end of line"
      else
        where = token.lexeme.starts_with?('"') ? token.lexeme : %("#{token.lexeme}")
        " at #{where}"
      end
    end

    private def report(line : Int, where : String, message : String)
      syntax_errors << Text.error("[line #{line}] Error#{where}: #{message}").tap do |error|
        STDERR.puts error
      end
    end
  end
end
