require "../spec_helper"

describe "Examples" do
  describe "parsing" do
    example_files = Dir.glob("examples/tested/*.lit").sort

    example_files.each do |file|
      it "parses #{file} without errors" do
        output_of {
          Lit::Parser.parse(Lit::Scanner.scan(File.read(file)))
        }.should be_empty
      end
    end
  end
end
