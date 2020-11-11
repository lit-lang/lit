require "./format"

module Lit
  module REPL
    extend self

    def run
      puts "Lit #{VERSION} - REPL\n\n"

      loop do
        line = read_line
        break if should_exit?(line)

        print "=> "
        puts evaluate(line)
      end

      puts "Bye! Cya..."
    end

    private def read_line
      Readline.readline("> ", add_history: true) || ""
    end

    private def evaluate(line : String) : String
      tokens = Scanner.scan(line)

      %([#{tokens.map(&.inspect).join(", ")}])
    rescue e
      Format.error("[ERROR] #{e}")
    end

    private def should_exit?(line : String) : Bool
      EXIT_REGEX.matches?(line) && !line.empty?
    end
  end
end
