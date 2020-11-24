require "./obj"
require "./token"
require "./runtime_error"

module Lit
  class Environment
    getter values
    @values = {} of String => Obj

    def define(name, value)
      @values[name] = value
    end

    def get(name : Token)
      return @values[name.lexeme] if @values.has_key? name.lexeme

      raise RuntimeError.new(name, "Undefined variable '#{name.lexeme}'.")
    end
  end
end
