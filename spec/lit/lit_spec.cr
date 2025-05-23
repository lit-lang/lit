require "../spec_helper"

describe Lit::Lit do
  it "has a version" do
    Lit::VERSION.should_not be_nil
  end

  describe ".run_file" do
    context "when file is not found" do
      it "outputs the error" do
        status, output = run_lit_in_process("./unknown-path/what.tf")
        dir = File.expand_path("../..", __DIR__)

        output.to_s.should contain "Error: File not found '#{dir}/unknown-path/what.tf'"
        status.exit_code.should eq Lit::ExitCode::NOINPUT.to_i
      end
    end
  end
end
