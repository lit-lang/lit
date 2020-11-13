require "../../src/lit/lit"

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
    output = output_of { Lit::Lit.run_file("spec/fixtures/#{name}.lit") }
    output.should_not match /fails/

    block.call(Feature.new(output))
  end
end
