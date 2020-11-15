require "readline"
require "./scanner"
require "./parser"
require "./token"
require "./repl"
require "./macros"
require "./format"

module Lit
  class Lit
    class_property had_error : Bool = false, had_runtime_error : Bool = false

    def self.run(src : String) : String?
      tokens = Scanner.scan(src)

      return if had_error
      return if had_runtime_error

      %([#{tokens.map(&.inspect).join(", ")}])
    end

    def self.run_repl
      REPL.run(self)
    end

    def self.run_file(path : String)
      run(File.read(path))
    rescue File::NotFoundError
      puts Format.error("Error: File not found!")
    ensure
      exit(65) if had_error
      exit(70) if had_runtime_error
    end

    def self.error(line : Int, message : String)
      report(line, "", message)
    end

    private def self.report(line : Int, where : String, message : String)
      puts(Format.error("[Line #{line}] Error#{where}: #{message}"))

      self.had_error = true
    end
  end
end
