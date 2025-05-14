require "spec"
require "stdio"
require "file_utils"
require "./support/create"
require "../src/lit"

Spec.before_suite do
  FileUtils.rm_rf("tmp")
  FileUtils.mkdir_p("tmp")
  Process.run("crystal", ["build", "--warnings", "all", "-p", "src/cli.cr", "-o", "bin/lit"])
end

macro token_type(type)
  Lit::TokenType::{{type}}
end

def run_lit_in_process(*args)
  output = IO::Memory.new
  error = IO::Memory.new
  status = Process.run("bin/lit", args, output: output, error: error)
  full_output = output.to_s + error.to_s

  {status, full_output, output, error}
end

def run_lit(file)
  status = Process::Status.new(0)
  full_output = output_of {
    begin
      result = Lit::Lit.run_file(file)
      code = result.is_a?(Lit::ExitCode) ? result : result[0]
      status = Process::Status.new(code.to_i)
    rescue e : Lit::Interpreter::Exit
      status = Process::Status.new(e.status.to_i)
    end
  }

  {status, full_output}
end

def output_of(&)
  Stdio.capture do |io|
    yield

    io.out.gets_to_end + io.err.gets_to_end
  end
end

def silence_output(&)
  Stdio.capture do
    yield
  end
end
