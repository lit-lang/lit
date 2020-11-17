require "../spec_helper"
require "../../src/lit/formatter"

describe Lit::Formatter do
  it "removes trailing whitespaces" do
    src = File.read("examples/formatter.lit")
    formatted_text = Lit::Formatter.format(src)

    formatted_text.should eq "puts('Formatting...')\n\nsum = fn { ( 1 + 1 ) }\n\nputs('Formatted!')\n"
  end
end
