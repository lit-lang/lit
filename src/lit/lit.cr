require "readline"
require "./exit_code"
require "./macros"
require "./token"
require "./scanner"
require "./parser"
require "./interpreter"
require "./repl"
require "./text"
require "./debug"

module Lit
  class Lit
    class_property? had_error = false, had_runtime_error = false
    class_property interpreter = Interpreter.new

    def self.run(src : String) : String?
      tokens = Scanner.scan(src)
      expressions = Parser.parse(tokens)

      return if had_error?
      return if had_runtime_error?

      # puts Text.hint Debug.s_expr(expressions)
      interpreter.interpret(expressions)
    end

    def self.run_repl
      REPL.run(self)
    end

    def self.run_file(path : String)
      run(File.read(path))
    rescue File::NotFoundError
      STDERR.puts Text.error("Error: File not found!")
      exit(ExitCode::NOINPUT)
    ensure
      exit(ExitCode::DATAERR) if had_error?
      exit(ExitCode::SOFTWARE) if had_runtime_error?
    end

    def self.runtime_error(error)
      STDERR.puts Text.error("[line #{error.token.line}] #{error.message}")

      self.had_runtime_error = true
    end

    def self.error(line : Int, message : String)
      report(line, "", message)
    end

    def self.error(token : Token, message : String)
      if token.type.eof?
        report(token.line, " at end", message)
      else
        report(token.line, " at #{token.lexeme.inspect}", message)
      end
    end

    private def self.report(line : Int, where : String, message : String)
      STDERR.puts Text.error("[line #{line}] Error#{where}: #{message}")

      self.had_error = true
    end
  end
end
