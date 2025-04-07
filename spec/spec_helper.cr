require "spec"
require "stdio"
require "file_utils"
require "./support/create"
require "./support/feature"
require "../src/lit"

Spec.before_suite do
  FileUtils.rm_rf("tmp")
  FileUtils.mkdir_p("tmp")
  Process.run("crystal", ["build", "--warnings", "all", "-p", "src/cli.cr", "-o", "bin/lit"])
end

def run_lit_script(*args)
  output = IO::Memory.new
  error = IO::Memory.new
  status = Process.run("bin/lit", args, output: output, error: error)
  full_output = output.to_s + error.to_s

  {status, full_output, output, error}
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
