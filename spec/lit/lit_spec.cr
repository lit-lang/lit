require "../spec_helper"

describe Lit::Lit do
  it "has a version" do
    Lit::VERSION.should_not be_nil
  end

  describe ".run_file" do
    context "when file is found" do
      it "runs the file" do
        Lit::Lit.had_error = false
        Lit::Lit.run_file("./examples/hello_world.lit").should eq(
          "[<IDENTIFIER 'print'>, <LEFT_PAREN '('>, <STRING '\"Hello world!\"': Hello world!>, " \
          "<RIGHT_PAREN ')'>, <SEMICOLON ';'>, <EOF ''>]"
        )
      end
    end

    context "when file is not found" do
      it "outputs the error" do
        output_of { Lit::Lit.run_file("./unkown-path/what.tf") }.should contain "File not found!"
      end
    end
  end
end
