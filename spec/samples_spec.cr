require "./spec_helper"

describe "samples" do
  sample_files = Dir.glob("samples/**/*.lit").sort!

  sample_files.each do |file|
    it "statically checks #{file} correctly" do
      src = File.read(file)
      interpreter = Lit::Interpreter.new(Lit::ErrorReporter.new)
      error_reporter = interpreter.error_reporter

      tokens = Lit::Scanner.new(src, error_reporter).scan
      statements = Lit::Parser.new(tokens, error_reporter).parse
      Lit::Resolver.new(interpreter, error_reporter).resolve(statements)

      error_reporter.success?.should be_true
    end
  end
end
