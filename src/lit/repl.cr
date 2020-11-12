require "./format"

module Lit
  module REPL
    EXIT_REGEX = /^\s*(#|$)|\b(quit|exit)\b/i

    extend self

    def run(runner)
      puts "Lit #{VERSION} - REPL\n\n"

      loop do
        line = read_line
        break if should_exit?(line)

        output = evaluate(line, runner)
        print_output(output)
      end

      puts "Bye! Cya..."
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
  end
end
