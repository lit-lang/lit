require "../spec_helper"
require "../../src/lit/formatter"

describe Lit::Formatter, focus: true do
  it "removes trailing whitespaces" do
    src = File.read("examples/formatter.lit")
    formatted_text = Lit::Formatter.format(src)

    formatted_text.should eq "puts('Formatting...')\nputs('Formatted!')\n"
  end
end
