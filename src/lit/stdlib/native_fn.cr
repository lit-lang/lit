module Lit
  module Native
    class Fn < Callable
      getter name

      def initialize(@name : String, @arity : Int32 | Range(Int32, Nil), @body : Proc(Interpreter, Array(Value), Token, Value)); end

      def arity
        @arity
      end

      def to_s
        "<native fn>"
      end

      def call(interpreter, arguments, token) : Value
        @body.call(interpreter, arguments, token)
      end
    end
  end
end
