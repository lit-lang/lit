module Lit
  module Text
    extend self

    macro format_as(str, *opts)
      {% for opt in opts %}
        str = as_{{opt}}(str)
      {% end %}

      str
    end

    def keyword(str)
      as_green(str)
    end

    def integer(str)
      as_blue(str)
    end

    def string(str)
      as_blue(str)
    end

    def warning(str : String)
      format_as(str, yellow, bold)
    end

    def error(str : String)
      format_as(str, red, bold)
    end

    def hint(str : String)
      format_as(str, italic)
    end

    private def as_black(str : String) : String
      "\e[30m#{str}\e[0m"
    end

    private def as_red(str : String) : String
      "\e[31m#{str}\e[0m"
    end

    private def as_green(str : String) : String
      "\e[32m#{str}\e[0m"
    end

    private def as_yellow(str : String) : String
      "\e[33m#{str}\e[0m"
    end

    private def as_blue(str : String) : String
      "\e[34m#{str}\e[0m"
    end

    private def as_magenta(str : String) : String
      "\e[35m#{str}\e[0m"
    end

    private def as_cyan(str : String) : String
      "\e[36m#{str}\e[0m"
    end

    private def as_gray(str : String) : String
      "\e[37m#{str}\e[0m"
    end

    private def as_bg_black(str : String) : String
      "\e[40m#{str}\e[0m"
    end

    private def as_bg_red(str : String) : String
      "\e[41m#{str}\e[0m"
    end

    private def as_bg_green(str : String) : String
      "\e[42m#{str}\e[0m"
    end

    private def as_bg_brown(str : String) : String
      "\e[43m#{str}\e[0m"
    end

    private def as_bg_blue(str : String) : String
      "\e[44m#{str}\e[0m"
    end

    private def as_bg_magenta(str : String) : String
      "\e[45m#{str}\e[0m"
    end

    private def as_bg_cyan(str : String) : String
      "\e[46m#{str}\e[0m"
    end

    private def as_bg_gray(str : String) : String
      "\e[47m#{str}\e[0m"
    end

    private def as_bold(str : String) : String
      "\e[1m#{str}\e[22m"
    end

    private def as_italic(str : String) : String
      "\e[3m#{str}\e[23m"
    end

    private def as_underline(str : String) : String
      "\e[4m#{str}\e[24m"
    end

    private def as_reverse_color(str : String) : String
      "\e[7m#{str}\e[27m"
    end
  end
end
