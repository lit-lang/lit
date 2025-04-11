require "./value"
require "./token"
require "./runtime_error"

module Lit
  class Environment
    getter values
    getter enclosing : Environment?

    # a binding is a pair of value and a boolean indicating if it is mutable
    class Binding
      property value : Value
      getter? mutable : Bool

      def initialize(@value, @mutable : Bool); end

      def uninitialized?
        @value == UNINITIALIZED
      end
    end

    @values = {} of String => Binding

    def initialize(@enclosing : Environment? = nil); end

    def define(name, value, mutable = false)
      @values[name] = Binding.new(value, mutable)
    end

    def get_at(distance : Int32, name : String)
      ancestor(distance).values[name].value
    end

    def get(name : Token)
      binding = @values[name.lexeme]? || raise RuntimeError.new(name, "Undefined variable '#{name.lexeme}'.")

      binding.value
    end

    def assign_at(distance : Int32, name : Token, value : Value)
      ancestor(distance).assign(name, value)
    end

    def assign(name, value) : Nil
      binding = @values[name.lexeme]? || raise RuntimeError.new(name, "Undefined variable '#{name.lexeme}'.")

      if binding.mutable? || binding.uninitialized?
        binding.value = value
      else
        raise RuntimeError.new(name, "Can't reassign '#{name.lexeme}' because it is declared with 'let'.")
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
