require "readline"
require "./scanner"
require "./token"

# TODO: Write documentation for `Lit`
module Lit
  VERSION    = "0.1.0"
  EXIT_REGEX = /^\s*(#|$)|\b(quit|exit)\b/i

  extend self

  def run(opts : Array(String) = ARGV)
    if opts.first?
      run_file(opts.first)
    else
      run_repl
    end
  end

  def run_repl
    puts "Lit #{VERSION} - REPL\n\n"

    loop do
      line = read_line
      break if should_exit?(line)

      print "=> "
      pp Scanner.scan(line)
    rescue e
      puts e
    end

    puts "Bye! Cya..."
  end

  def run_file(path : String) : Array(Token)
    Scanner.scan(File.read(path))
  rescue
    puts "File not found!"

    [] of Token
  end

  private def read_line
    Readline.readline("> ", add_history: true) || ""
  end

  private def should_exit?(line : String) : Bool
    EXIT_REGEX.matches?(line) && !line.empty?
  end
end
