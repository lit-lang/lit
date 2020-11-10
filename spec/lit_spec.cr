require "./spec_helper"

describe Lit do
  it "has a version" do
    Lit::VERSION.should_not be_nil
  end

  describe ".run_file" do
    context "when file is not found" do
      it "outputs the error" do
        output_of { Lit.run_file("./unkown-path/what.tf") }.should eq "File not found!\n"
      end
    end
  end
end
