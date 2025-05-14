require "./text"

module Lit
  module REPL
    QUIT_REGEX = /^\s*quit\s*$/i
    HELP_REGEX = /^\s*help\s*$/i

    class_getter interpreter = Interpreter.new(ErrorReporter.new)

    extend self

    def run(runner)
      display_lit_version
      display_hint

      loop do
        line = read_line
        break if should_quit?(line)
        next if display_help?(line)

        _output = evaluate(line, runner)
        # print_output(output)
      end
    end

    private def read_line
      (Readline.readline("lit> ", add_history: true) || "") + "\n"
    end

    private def evaluate(line : String, runner)
      ::Lit.with_current_file_path("REPL") do
        _result = runner.run(line, interpreter: interpreter)
        interpreter.error_reporter.reset!
      end
    end

    private def print_output(output)
      return if output.nil?

      puts "=> #{output}"
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
