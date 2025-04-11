require "./value"
require "./interpreter"

module Lit
  abstract class Callable
    def arity : Int32
      0
    end

    abstract def call(interpreter : Interpreter, arguments : Array(Value), token : Token) : Value
  end
end
