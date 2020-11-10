require "./spec_helper"

describe Lit do
  it "has a version" do
    Lit::VERSION.should_not be_nil
  end

  describe ".run" do
    context "when file is given" do
      it "runs the file" do
        argv = ["./examples/hello_world.lit"]

        Lit.run(argv).as(Array(Lit::Token)).map(&.type).should eq [
          token(IDENTIFIER),
          token(LEFT_PAREN),
          token(STRING),
          token(RIGHT_PAREN),
          token(EOF),
        ]
      end
    end

    context "when no file is given" do
      it "runs the repl" do
        Lit.run([] of String).should eq "repl"
      end
    end
  end

  describe ".run_file" do
    context "when file is found" do
      it "runs the file" do
        Lit.run_file("./examples/hello_world.lit").should be_a Array(Lit::Token)
      end
    end

    context "when file is not found" do
      it "outputs the error" do
        output_of { Lit.run_file("./unkown-path/what.tf") }.should eq "File not found!\n"
      end
    end
  end
end
