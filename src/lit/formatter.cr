require "./format"

module Lit
  # TODO:
  # This module makes very simple formatting on LIT files.
  # It's regex based, so it's not very elegant, but it gets the job done.
  # In the future I'll parse the code and "pretty print" it. It should
  # be more powerful.
  module Formatter
    extend self

    def format(input = nil)
      error("No input given") if no_input?(input)

      if input
        format_pipeline(input)
      else
        File.write(ARGV[1], format_pipeline(File.read(ARGV[1])))
      end
    rescue File::NotFoundError
      error("File not found")
    end

    private def format_pipeline(src)
      remove_trailing_whitespaces(src)
        .try { |s| remove_multiple_spaces(s) }
        .try { |s| add_space_between_operators(s) }
        .try { |s| remove_multiple_new_lines(s) }
        .try { |s| remove_multiple_new_lines_at_begin(s) }
        .try { |s| remove_unecessary_curly_brackets(s) }
        .try { |s| add_newline_at_end(s) }
    end

    private def remove_trailing_whitespaces(src)
      src.split("\n").map(&.gsub(/[ \r\t\f\v]+$/m, "")).join("\n")
    end

    private def remove_multiple_new_lines(src)
      src.gsub(/([\n]$){2,}/m, "\n")
    end

    private def remove_multiple_new_lines_at_begin(src)
      if src.starts_with?("\n")
        src = src.lchop("\n")
        src = remove_multiple_new_lines_at_begin(src)
      end

      src
    end

    private def remove_multiple_spaces(src)
      src.gsub(/\S\K[ \t]{2,}/m, " ")
    end

    private def add_space_between_operators(src)
      with_space_before = src.gsub(/([_a-zA-Z0-9]+)[+\-=\/]/m) { |s| add_space(s) }
      with_space_before_and_after = with_space_before.gsub(/[+\-=\/]([_a-zA-Z0-9]+)/m) { |s| add_space(s) }

      with_space_before_and_after
    end

    private def remove_unecessary_curly_brackets(src)
      src.gsub(/\{[\s]*return.*;\s*\}/) { |s| s[1..-2] }
    end

    private def add_newline_at_end(src)
      src.ends_with?("\n") ? src : src + "\n"
    end

    private def error(msg)
      puts Format.error(msg)
      exit(1)
    end

    private def no_input?(input)
      input.nil? && ARGV[1]?.nil?
    end

    private def add_space(str)
      str.strip.split(/([+\-=\/])/).reject!(&.empty?).join(" ")
    end
  end
end
