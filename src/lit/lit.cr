require "readline"
require "./scanner"
require "./token"
require "./repl"

# TODO: Write documentation for `Lit`
module Lit
  class Lit
    def self.run(opts : Array(String) = ARGV)
      if opts.first?
        run_file(opts.first)
      else
        run_repl
      end
    end

    def self.run_repl
      REPL.run
    end

    def self.run_file(path : String) : Array(Token)
      Scanner.scan(File.read(path))
    rescue File::NotFoundError
      puts "File not found!"

      [] of Token
    end
  end
end
