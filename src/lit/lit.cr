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
    def self.run(src : String, interpreter = Interpreter.new(ErrorReporter.new)) : {Bool, ErrorReporter}
      error_reporter = interpreter.error_reporter

      tokens = Scanner.new(src, error_reporter).scan
      statements = Parser.new(tokens, error_reporter).parse

      return {false, error_reporter} if error_reporter.had_syntax_error?

      Resolver.new(interpreter, error_reporter).resolve(statements)

      return {false, error_reporter} if error_reporter.had_syntax_error?

      interpreter.interpret(statements)

      {error_reporter.success?, error_reporter}
    end

    def self.run_repl
      REPL.run
    end

    def self.run_code(code : String)
      _, error_reporter = run(code)

      return ExitCode::DATAERR if error_reporter.had_syntax_error?
      return ExitCode::SOFTWARE if error_reporter.had_runtime_error?

      ExitCode::OK
    end

    def self.run_file(path : String) : ExitCode | {ExitCode, String}
      # TODO: maybe this should raise Exit already?
      full_path = File.expand_path(path)
      src = read_file(full_path)
      return src if !src.is_a?(String)

      ::Lit.with_current_file_path(full_path) do
        run_code(src)
      end
    end

    def self.read_file(path : String) : String | {ExitCode, String}
      File.read(path)
    rescue File::NotFoundError
      {ExitCode::NOINPUT, "File not found '#{path}'"}
    rescue e : IO::Error
      {ExitCode::NOINPUT, "Unable to read file: #{path}. Reason: #{e.message}"}
    end
  end
end
