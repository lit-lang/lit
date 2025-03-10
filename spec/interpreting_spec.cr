require "./spec_helper"

describe "Examples" do
  describe "interpreting" do
    example_files = Dir.glob("spec/e2e/**/*.lit").sort

    if ENV["ONLY"]?
      example_files.select!(&.includes?(ENV["ONLY"]))
    end

    example_files.each do |file|
      it "interprets #{file} correctly" do
        will_error = false
        expected = File.read_lines(file)
          .compact_map { |line|
            if line.includes?("# error: ")
              will_error = true
              "\e[1m\e[31m" + line.split("# error: ").last + "\e[0m\e[22m"
            elsif line.includes?("# expect: ")
              line.split("# expect: ").last
            end
          }.join("\n")

        expected += "\n" if !expected.empty?

        status, full_output = run_script(<<-CRYSTAL)
          Lit.run(["#{file}"])
        CRYSTAL

        full_output.should eq expected
        will_error ? status.not_nil!.success?.should be_false : status.not_nil!.success?.should be_true
      end
    end
  end
end
