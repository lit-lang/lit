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

    def get_method(name) : Callable?
      get(name).try(&.as(Callable)) rescue nil
    end

    def call_method(name, arguments, interpreter)
      if method = get_method(name)
        method.call(interpreter, arguments, name)
      else
        raise RuntimeError.new(name, "Undefined method '#{name.lexeme}' for #{type.name}.")
      end
    end

    def set(name, value)
      fields[name.lexeme] = value
    end

    def to_s
      "#{type.name}(#{fields.map { |k, v| "#{k}: #{v}" }.join(", ")})"
    end
  end
end
