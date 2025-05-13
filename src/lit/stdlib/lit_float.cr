require "../instance"
require "./native_fn"

module Lit
  class LitFloat < Instance
    TYPE  = Type.new("Float", {} of String => Function)
    EMPTY = {} of String => Value

    def initialize(value : Float64)
      super(TYPE, EMPTY)
      @value = value
    end

    def get(name : Token) : Value
      case name.lexeme
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
      when "is_positive?"
        ::Lit::Native::Fn.new(name.lexeme, 0, ->(_interpreter : Interpreter, _arguments : ::Array(Value), _token : Token) : Value {
          @value > 0
        })
      when "is_negative?"
        ::Lit::Native::Fn.new(name.lexeme, 0, ->(_interpreter : Interpreter, _arguments : ::Array(Value), _token : Token) : Value {
          @value < 0
        })
      when "truncate"
        ::Lit::Native::Fn.new(name.lexeme, 1, ->(interpreter : Interpreter, arguments : ::Array(Value), token : Token) : Value {
          decimals = arguments[0]

          unless decimals.is_a?(Int64)
            raise RuntimeError.new(token, "Expected Integer as the first argument, got #{interpreter.type_of(decimals)}.")
          end
          if decimals < 0
            raise RuntimeError.new(token, "Expected a positive Integer as the first argument, got #{decimals}.")
          end

          factor = 10_f64 ** decimals
          ((@value * factor).to_i).to_f / factor
        })
      when "to_i"
        ::Lit::Native::Fn.new(name.lexeme, 0, ->(_interpreter : Interpreter, _arguments : ::Array(Value), _token : Token) : Value {
          @value.to_i64
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
