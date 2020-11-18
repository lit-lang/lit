require "../spec_helper"
require "../../src/lit/formatter"

describe Lit::Formatter do
  it "removes trailing whitespaces" do
    src = File.read("examples/formatter.lit")
    formatted_text = Lit::Formatter.format(src)

    formatted_text.should eq <<-LIT
    Math = {
      sum = fn { |a, b|
        (a + b)
      }
    }

    LIT
  end
end
