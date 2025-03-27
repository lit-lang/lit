require "./value"
require "./token"
require "./runtime_error"

module Lit
  class Environment
    getter values
    @values = {} of String => Value

    def initialize(@enclosing : Environment? = nil); end

    def define(name, value)
      @values[name] = value
    end

    def get(name : Token)
      if @values.has_key? name.lexeme
        @values[name.lexeme]
      elsif enclosing = @enclosing
        enclosing.get(name) # TODO: Maybe this could be faster iteratively, not recursively
      else
        raise RuntimeError.new(name, "Undefined variable '#{name.lexeme}'.")
      end
    end

    def assign(name, value) : Nil
      if @values.has_key?(name.lexeme)
        @values[name.lexeme] = value
      elsif enclosing = @enclosing
        enclosing.assign(name, value) # TODO: Maybe this could be faster iteratively, not recursively
      else
        raise RuntimeError.new(name, "Undefined variable '#{name.lexeme}'.")
      end
    end
  end
end
