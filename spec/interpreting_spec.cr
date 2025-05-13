require "./spec_helper"

describe "e2e tests", tags: "e2e" do
  example_files = Dir.glob("spec/e2e/**/*.lit").reject(&.includes?("__")).sort!

  if ENV["ONLY"]? && !ENV["ONLY"].empty?
    all = example_files.size
    selections = ENV["ONLY"].split
    example_files.select! { |file| selections.any? { |s| file.includes?(s) } }
    puts "running #{example_files.size} of #{all} tests"
  end

  example_files.each do |file|
    it "interprets #{file} correctly" do
      will_error = false
      expected = File.read_lines(file)
        .compact_map { |line|
          # skip commented out lines, but not assertions
          next if line.strip.starts_with?("#") && !line.strip.starts_with?("# expect: ") && !line.strip.starts_with?("# error: ")

          if line.includes?("# error: ")
            will_error = true
            "\e[1m\e[31m" + line.split("# error: ").last + "\e[0m\e[22m"
          elsif line.includes?("# expect: ")
            line.split("# expect: ").last
          end
        }.join("\n")

      expected += "\n" if !expected.empty?

      if ENV["PROCESS"]?
        status, full_output = run_lit_in_process(file)
      else
        status, full_output = run_lit(file)
      end

      full_output.should eq expected
      will_error ? status.not_nil!.success?.should be_false : status.not_nil!.success?.should be_true
    end
  end
end
