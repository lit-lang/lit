require "../spec_helper"

describe "Examples" do
  describe "interpreting" do
    example_files = Dir.glob("examples/tested/*.lit").sort

    example_files.each do |file|
      it "interprets #{file} correctly" do
        expected = File.read_lines(file)
          .compact_map do |line|
            if line.includes?("# error: ")
              "\e[1;31m" + line.split("# error: ").last + "\e[0m"
            elsif line.includes?("# expect: ")
              line.split("# expect: ").last
            end
          end
          .join("\n") + "\n"
        raise "Missing expectation" if expected.empty?

        output_of { Process.fork { Lit.run([file]) } }
      end
    end
  end
end
