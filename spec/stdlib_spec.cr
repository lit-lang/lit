require "./spec_helper"

describe "stdlib tests", tags: "e2e" do
  test_files = Dir.glob("spec/stdlib/**/*.lit").sort!

  test_files.each do |file|
    it "interprets #{file} correctly" do
      status, output = run_lit(file)

      unless status.success?
        fail "Failed spec:\n#{output}"
      end
    end
  end
end
