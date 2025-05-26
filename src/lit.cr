require "option_parser"
require "./lit/lit"

module Lit
  VERSION = "0.3.0"

  private class_property current_file_path = ""

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
        begin
          with_current_file_path("eval") do
            Lit.run_code(code)
          end
          exit
        rescue e : ::Lit::Interpreter::Exit
          exit(e.status.to_i)
        end
      end

      parser.invalid_option do
        # pass down as ARGV
      end
    end

    begin
      if opts.first?
        result = Lit.run_file(opts.first)
        exit_code = if result.is_a?(ExitCode)
                      result
                    else
                      ErrorReporter.report_error(result[1])
                      result[0]
                    end

        exit(exit_code.to_i)
      else
        Lit.run_repl
      end
    rescue e : ::Lit::Interpreter::Exit
      exit(e.status.to_i)
    end
  end

  def self.with_current_file_path(file : String, &)
    old_path = current_file_path
    self.current_file_path = file

    begin
      yield
    ensure
      self.current_file_path = old_path
    end
  end

  def self.current_file_name : String
    Path[current_file_path].basename
  end

  def self.expand_path(path : String) : String
    File.expand_path(path, File.dirname(current_file_path))
  end
end
