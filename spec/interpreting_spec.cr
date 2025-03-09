require "./spec_helper"

describe "Examples" do
  describe "interpreting" do
    example_files = Dir.glob("spec/e2e/**/*.lit").sort

    example_files.each do |file|
      it "interprets #{file} correctly" do
        will_error = false
        expected = File.read_lines(file)
          .compact_map do |line|
            if line.includes?("# error: ")
              will_error = true
              "\e[1m\e[31m" + line.split("# error: ").last + "\e[0m\e[22m"
            elsif line.includes?("# expect: ")
              line.split("# expect: ").last
            end
          end
          .join("\n") + "\n"
        raise "Missing expectation" if expected.empty?

        status = nil
        output_of {
          status = Process.fork { Lit.run([file]) }.wait
        }.should eq expected
        will_error ? status.not_nil!.success?.should be_false : status.not_nil!.success?.should be_true
      end
    end
  end
end
