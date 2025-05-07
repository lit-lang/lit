module Lit
  class ErrorReporter
    getter? had_syntax_error
    getter? had_runtime_error

    def initialize
      reset!
    end

    def reset!
      @had_syntax_error = false
      @had_runtime_error = false
    end

    def report_syntax_error(line : Int, message : String)
      report(line, "", message)
    end

    def report_syntax_error(token : Token, message : String)
      report(token.line, syntax_error_location(token), message)
    end

    def report_runtime_error(error)
      STDERR.puts Text.error("[line #{error.token.line}] Runtime error: #{error.message}")

      @had_runtime_error = true
    end

    def success?
      !had_syntax_error? && !had_runtime_error?
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
      STDERR.puts Text.error("[line #{line}] Error#{where}: #{message}")
      @had_syntax_error = true
    end
  end
end
