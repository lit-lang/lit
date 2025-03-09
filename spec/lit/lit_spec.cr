require "../spec_helper"

describe Lit::Lit do
  it "has a version" do
    Lit::VERSION.should_not be_nil
  end

  describe ".run_file" do
    context "when file is not found" do
      it "outputs the error" do
        output_of { Process.fork { Lit::Lit.run_file("./unknown-path/what.tf") } }.should contain "File not found!"
      end
    end
  end
end
