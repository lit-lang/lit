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

      raise RuntimeError.new(name, "Undefined property '#{name.lexeme}' for #{type.name}.")
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

    def set(name, value, in_initializer)
      if fields.has_key?(name.lexeme) || in_initializer
        fields[name.lexeme] = value
      else
        raise RuntimeError.new(name, "Undefined property '#{name.lexeme}' for #{type.name}.")
      end
    end

    def to_s(interpreter, token) : String
      "#{type.name}(#{fields.map { |k, v| "#{k}: #{::Lit.inspect_value(v, interpreter, token)}" }.join(", ")})"
    end
  end
end
