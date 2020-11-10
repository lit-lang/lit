require "./scanner"
require "./token"

# TODO: Write documentation for `Lit`
module Lit
  VERSION = "0.1.0"
  extend self

  def run(opts : Array(String) = ARGV)
    if opts.first?
      run_file(opts.first)
    else
      run_repl
    end
  end

  def run_repl
    "repl"
  end

  def run_file(path : String)
    File.read(path)
  rescue
    puts "File not found!"
  end
end
