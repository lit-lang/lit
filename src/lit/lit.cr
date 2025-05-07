require "readline"
require "./exit_code"
require "./token"
require "./scanner"
require "./parser"
require "./resolver"
require "./interpreter"
require "./repl"
require "./error_reporter"
require "./text"

module Lit
  class Lit
    private class_property error_reporter = ErrorReporter.new
    private class_property interpreter = Interpreter.new

    def self.run(src : String)
      tokens = Scanner.scan(src)
      statements = Parser.parse(tokens)

      return false if had_error?

      Resolver.new(interpreter).resolve(statements)

      return false if had_error?

      interpreter.interpret(statements)

      !had_runtime_error?
    end

    def self.run_repl
      REPL.run(self)
    end

    def self.run_code(code : String)
      run(code)

      return ExitCode::DATAERR if had_error?
      return ExitCode::SOFTWARE if had_runtime_error?

      ExitCode::OK
    end

    def self.run_file(path : String)
      run_code(File.read(path))
    rescue File::NotFoundError
      STDERR.puts Text.error("Error: File not found!")

      ExitCode::NOINPUT
    rescue IO::Error
      STDERR.puts Text.error("Error: Unable to read file!")

      ExitCode::NOINPUT
    end

    def self.reset_errors
      self.error_reporter = ErrorReporter.new
    end

    def self.runtime_error(error)
      error_reporter.add_runtime_error(error)
    end

    def self.error(line : Int, message : String)
      error_reporter.add_syntax_error(line, message)
    end

    def self.error(token : Token, message : String)
      error_reporter.add_syntax_error(token, message)
    end

    def self.had_error? : Bool
      error_reporter.had_syntax_error?
    end

    def self.had_runtime_error? : Bool
      error_reporter.had_runtime_error?
    end
  end
end
