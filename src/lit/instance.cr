require "./interpreter"
require "./value"

module Lit
  class Instance
    private getter fields
    getter type

    def initialize(@type : Type, @fields = {} of String => Value); end

    def get(name)
      if fields.has_key?(name.lexeme)
        return fields[name.lexeme]
      end

      if method = type.find_method(name.lexeme)
        return method.bind(self)
      end

      raise RuntimeError.new(name, "Undefined property '#{name.lexeme}'.")
    end

    def set(name, value)
      fields[name.lexeme] = value
    end

    # TODO: change this representation to something like Ruby or Rust
    def to_s
      "#{type.name} instance"
    end
  end
end
