require "../instance"
require "./native_fn"

module Lit
  class LitFloat < Instance
    TYPE  = Type.new("LitFloat", {} of String => Function)
    EMPTY = {} of String => Value

    def initialize(value : Float64)
      super(TYPE, EMPTY)
      @value = value
    end

    def get(name : Token) : Value
      case name.lexeme
      when "add"
        ::Lit::Native::Fn.new(name.lexeme, 1, ->(_interpreter : Interpreter, arguments : ::Array(Value), token : Token) : Value {
          other = arguments[0]
          if other.is_a?(Float64)
            @value + other
          else
            raise RuntimeError.new(token, "Expected number as the first argument.")
          end
        })
      when "abs"
        ::Lit::Native::Fn.new(name.lexeme, 0, ->(_interpreter : Interpreter, _arguments : ::Array(Value), _token : Token) : Value {
          @value.abs
        })
      when "floor"
        ::Lit::Native::Fn.new(name.lexeme, 0, ->(_interpreter : Interpreter, _arguments : ::Array(Value), _token : Token) : Value {
          @value.floor
        })
      when "ceil"
        ::Lit::Native::Fn.new(name.lexeme, 0, ->(_interpreter : Interpreter, _arguments : ::Array(Value), _token : Token) : Value {
          @value.ceil
        })
      when "round"
        ::Lit::Native::Fn.new(name.lexeme, 0, ->(_interpreter : Interpreter, _arguments : ::Array(Value), _token : Token) : Value {
          @value.round
        })
      when "to_s"
        ::Lit::Native::Fn.new(name.lexeme, 0, ->(interpreter : Interpreter, _arguments : ::Array(Value), token : Token) : Value {
          ::Lit.stringify_value(@value, interpreter, token)
        })
      else
        super
      end
    end

    def set(name : Token, value : Value)
      raise RuntimeError.new(name, "Cannot set properties on array.")
    end
  end
end
