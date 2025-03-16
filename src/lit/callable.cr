require "./value"
require "./interpreter"

module Lit
  class Callable
    def arity : Int32
      0
    end

    def call(interpreter : Interpreter, arguments : Array(Value)) : Value
      raise "Not implemented"
    end
  end
end
