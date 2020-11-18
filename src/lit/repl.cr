require "./text"

module Lit
  module REPL
    EXIT_REGEX = /^\s*(#|$)|\b(quit|exit)\b/i
    HELP_REGEX = /^\s*(#|$)|\b(help)\b/i

    extend self

    def run(runner)
      display_lit_version
      display_hint

      loop do
        line = read_line
        break if should_exit?(line)
        next if display_help?(line)

        output = evaluate(line, runner)
        print_output(output)
      end

      display_goodbye
    end

    private def read_line
      Readline.readline("lit> ", add_history: true) || ""
    end

    private def evaluate(line : String, runner) : String?
      result = runner.run(line)
      runner.had_error = false

      result
    end

    private def print_output(output)
      return if output.nil?

      puts "=> #{output}"
    end

    private def should_exit?(line : String) : Bool
      EXIT_REGEX.matches?(line) && !line.empty?
    end

    private def display_help?(line : String) : Bool
      asked_for_help = HELP_REGEX.matches?(line) && !line.empty?
      display_help if asked_for_help

      asked_for_help
    end

    private def display_lit_version
      puts "LIT #{VERSION} - REPL"
    end

    private def display_hint
      puts Text.hint("Hint: Type 'help' to see available commands\n\n")
    end

    private def display_help : Nil
      puts "Available commands:"
      puts "  quit | exit    exits repl"
      puts "  help           displays this message"
      puts
    end

    private def display_goodbye
      puts "Bye, cya!"
    end
  end
end
