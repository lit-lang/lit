require "./format"

module Lit
  module Formatter
    extend self

    def format(input = nil)
      error("No input given") if no_input?(input)

      if input
        format_pipeline(input)
      else
        File.write(ARGV[1], format_pipeline(File.read(ARGV[1])))
      end
    rescue
      error("File not found")
    end

    private def format_pipeline(src)
      remove_trailing_whitespaces(src)
        .try { |result| remove_multiple_new_lines(result) }
        .try { |result| add_newline_at_end(result) }
    end

    private def remove_trailing_whitespaces(src)
      src.split("\n").map(&.gsub(/[ \r\t\f\v]+$/m, "")).join("\n")
    end

    private def remove_multiple_new_lines(src)
      src.gsub(/(\n)+/m, "\n")
    end

    private def add_newline_at_end(src)
      src + "\n"
    end

    private def error(msg)
      puts Format.error(msg)
      exit(1)
    end

    private def no_input?(input)
      input.nil? && ARGV[1]?.nil?
    end
  end
end
