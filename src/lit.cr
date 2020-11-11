require "readline"
require "./scanner"
require "./token"
require "./repl"

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
    REPL.run
  end

  def run_file(path : String) : Array(Token)
    Scanner.scan(File.read(path))
  rescue File::NotFoundError
    puts "File not found!"

    [] of Token
  end
end
