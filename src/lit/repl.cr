require "./text"

module Lit
  module REPL
    QUIT_REGEX = /^\s*quit\s*$/i
    HELP_REGEX = /^\s*help\s*$/i

    private class_getter interpreter : Interpreter = (Interpreter.new(ErrorReporter.new).tap do |interpreter|
      interpreter.environment.define("_", nil)
    end)
    private delegate error_reporter, to: interpreter

    extend self

    def run
      display_lit_version
      display_hint

      loop do
        line = read_line
        break if should_quit?(line)
        next if display_help?(line)

        result = evaluate(line)
        print_result(result)
      end
    end

    private def read_line
      (Readline.readline("lit> ", add_history: true) || "") + "\n"
    end

    private def evaluate(line : String)
      value = ::Lit.with_current_file_path("REPL") do
        tokens = Scanner.new(line, error_reporter).scan
        statements = Parser.new(tokens, error_reporter).parse

        break :error if error_reporter.had_syntax_error?

        Resolver.new(interpreter, error_reporter).resolve(statements)

        break :error if error_reporter.had_syntax_error?

        result = interpreter.interpret(statements)
        interpreter.environment.define("_", result)

        {result, ::Lit.inspect_value(result, interpreter, tokens.first)}
      end

      error_reporter.reset!

      value
    end

    private def print_result(result)
      return if result.is_a? Symbol

      value, string = result

      colorized_value = case value
                        in String
                          Text.string(string)
                        in Int64, Float64
                          Text.number(string)
                        in Nil, Bool
                          Text.keyword(string)
                        in Type, Function, Callable, Uninitialized, Instance
                          Text.default(string)
                        end

      puts "=> #{colorized_value}"
    end

    private def should_quit?(line : String) : Bool
      QUIT_REGEX.matches?(line)
    end

    private def display_help?(line : String) : Bool
      asked_for_help = HELP_REGEX.matches?(line)
      display_help if asked_for_help

      asked_for_help
    end

    private def display_lit_version
      puts "Lit #{VERSION} - REPL"
    end

    private def display_hint
      puts Text.hint("Hint: Type 'help' to see available commands\n\n")
    end

    private def display_help : Nil
      puts "Available commands:"
      puts "  quit\tquits the REPL"
      puts "  help\tdisplays this message"
      puts
    end
  end
end
