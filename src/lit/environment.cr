require "./obj"
require "./token"
require "./runtime_error"

module Lit
  class Environment
    getter values
    @values = {} of String => Obj

    def initialize(@enclosing : Environment? = nil); end

    def define(name, value)
      @values[name] = value
    end

    def get(name : Token)
      return @values[name.lexeme] if @values.has_key? name.lexeme
      return @enclosing.not_nil!.get(name) if @enclosing

      raise RuntimeError.new(name, "Undefined variable '#{name.lexeme}'.")
    end

    def assign(name, value) : Nil
      return (@values[name.lexeme] = value) if @values.has_key?(name.lexeme)
      return @enclosing.not_nil!.assign(name, value) if @enclosing

      raise RuntimeError.new(name, "Undefined variable '#{name.lexeme}'.")
    end
  end
end
