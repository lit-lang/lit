require "spec"
require "stdio"
require "file_utils"
require "./support/create"
require "./support/feature"
require "../src/lit"

Spec.before_suite do
  FileUtils.mkdir_p("tmp")
end

Spec.after_suite do
  FileUtils.rm_rf("tmp")
end

def run_script(script_content)
  temp_file = File.tempfile("test_script", ".cr", dir: "tmp") do |file|
    file.print(<<-CRYSTAL)
      require "../src/lit"
      #{script_content}
    CRYSTAL
  end

  output = IO::Memory.new
  error = IO::Memory.new
  status = Process.run("crystal", args: ["run", "--warnings", "none", temp_file.path], output: output, error: error)
  # Ignore warnings
  # See: https://github.com/crystal-lang/crystal/issues/13846
  error = error.to_s.lines.reject(&.starts_with?("ld: warning:")).join("\n")
  error += "\n" if !error.empty?
  full_output = output.to_s + error

  {status, full_output, output, error}
ensure
  temp_file.try(&.delete)
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
