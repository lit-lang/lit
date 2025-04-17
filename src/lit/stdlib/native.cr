require "../interpreter"
require "./lit_array"
require "./native_fn"

module Lit
  module Stdlib
    module Native
      def self.all
        [
          ::Lit::Native::Fn.new("Array", 0.., ->(_interpreter : Interpreter, arguments : ::Array(Value), _token : Token) : Value {
            if arguments.size == 0
              LitArray.new
            else
              LitArray.new(arguments)
            end
          }),
          ::Lit::Native::Fn.new("clock", 0, ->(_interpreter : Interpreter, _arguments : ::Array(Value), _token : Token) : Value {
            Time.local.to_unix_f
          }),
          ::Lit::Native::Fn.new("readln", 0, ->(_interpreter : Interpreter, _arguments : ::Array(Value), _token : Token) : Value {
            gets || ""
          }),
          ::Lit::Native::Fn.new("open", 1, ->(_interpreter : Interpreter, arguments : ::Array(Value), token : Token) : Value {
            filename = arguments[0]

            if filename.is_a?(String)
              File.read(filename)
            else
              raise RuntimeError.new(token, "Expected string as the first argument.")
            end
          }),
          ::Lit::Native::Fn.new("typeof", 1, ->(interpreter : Interpreter, arguments : ::Array(Value), _token : Token) : Value {
            interpreter.type_of(arguments[0])
          }),
        ]
      end
    end
  end
end
