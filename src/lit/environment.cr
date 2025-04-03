require "./value"
require "./token"
require "./runtime_error"

module Lit
  class Environment
    getter values
    getter enclosing : Environment?
    @values = {} of String => Value

    def initialize(@enclosing : Environment? = nil); end

    def define(name, value)
      @values[name] = value
    end

    def get_at(distance : Int32, name : Token)
      ancestor(distance).get(name)
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

    def assign_at(distance : Int32, name : Token, value : Value)
      ancestor(distance).assign(name, value)
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

    private def ancestor(distance : Int32) : Environment
      env = self
      distance.times do
        env = env.enclosing.not_nil!
      end
      env
    end
  end
end
