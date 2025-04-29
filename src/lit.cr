require "option_parser"
require "./lit/lit"

module Lit
  VERSION = "0.2.0"

  def self.run(opts : Array(String) = ARGV)
    OptionParser.parse do |parser|
      parser.banner = "Usage: lit [options] [file]"

      parser.on("-v", "--version", "Show version") do
        puts "Lit #{VERSION}"
      end

      parser.on("-h", "--help", "Show this help message") do
        puts parser
      end

      parser.on("-e CODE", "--eval=CODE", "Execute the given code") do |code|
        Lit.run_code("#{code}")
        exit
      end

      parser.invalid_option do |flag|
        STDERR.puts Text.error("Error: #{flag} is not a valid option.")
        STDERR.puts parser
        exit(1)
      end
    end

    if opts.first?
      Lit.run_file(opts.first)
    else
      Lit.run_repl
    end
  end
end
