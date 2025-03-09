require "../spec_helper"

describe "Examples" do
  describe "interpreting" do
    example_files = Dir.glob("examples/tested/*.lit").sort

    example_files.each do |file|
      it "interprets #{file} correctly" do
        expected = File.read_lines(file)
          .select { |line| line.includes?("# expect: ") }
          .map { |line| line.split("# expect: ").last }
          .join("\n") + "\n"
        raise "Missing expectation" if expected.empty?

        output_of { Lit.run([file]) }.should eq expected
      end
    end
  end
end
