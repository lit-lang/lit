require "spec"
require "stdio"
require "./support/create"
require "./support/feature"
require "../src/lit"

def output_of
  Stdio.capture do |io|
    yield

    io.out.gets_to_end
  end
end

def silence_output
  Stdio.capture do
    yield
  end
end
