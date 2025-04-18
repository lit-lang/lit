require "../spec_helper"

describe Lit::Lit do
  it "has a version" do
    Lit::VERSION.should_not be_nil
  end

  describe ".run_file" do
    context "when file is not found" do
      it "outputs the error" do
        status, output = run_lit_script("./unknown-path/what.tf")
        output.to_s.should contain "File not found!"
        status.exit_code.should eq ExitCode::NOINPUT
      end
    end
  end
end
