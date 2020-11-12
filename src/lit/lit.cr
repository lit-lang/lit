require "readline"
require "./scanner"
require "./token"
require "./repl"
require "./macros"

# TODO: Write documentation for `Lit`
module Lit
  class Lit
    class_property had_error : Bool = false, had_runtime_error : Bool = false

    def self.run(src : String)
      tokens = Scanner.scan(src)

      return if had_error
      return if had_runtime_error

      %([#{tokens.map(&.inspect).join(", ")}])
    end

    def self.run_repl
      REPL.run
    end

    def self.run_file(path : String)
      run(File.read(path))
    rescue File::NotFoundError
      puts "File not found!"
    ensure
      exit(65) if had_error
      exit(70) if had_runtime_error
    end
  end
end
