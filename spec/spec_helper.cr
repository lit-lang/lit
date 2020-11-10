require "spec"
require "stdio"
require "../src/lit"

macro token(type)
  Lit::TokenType::{{type}}
end

def output_of
  Stdio.capture do |io|
    yield
    io.out.gets_to_end
  end
end

class Feature
  def initialize(@features : String); end

  def assert(expected_feature)
    it "asserts that #{expected_feature}" do
      @features.should match /#{expected_feature}/
    end
  end
end

def feature(name, &block : Feature ->)
  describe name do
    output = output_of { Cryox::Lox.run_file("spec/fixtures/#{name}.lox") }
    output.should_not match /fails/

    block.call(Feature.new(output))
  end
end
