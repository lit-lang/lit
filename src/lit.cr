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

    line = ""
    loop do
      print "> "

      line = gets || ""
      break if line =~ EXIT_REGEX && !line.empty?

      print "=> "
      pp Scanner.scan(line)
    rescue e
      puts e
    end
  end

  def run_file(path : String) : Array(Token)
    Scanner.scan(File.read(path))
  rescue
    puts "File not found!"

    [] of Token
  end
end
