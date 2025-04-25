require "../instance"
require "./native_fn"

module Lit
  class LitInteger < Instance
    TYPE  = Type.new("Integer", {} of String => Function)
    EMPTY = {} of String => Value

    @value : Int64

    def initialize(value)
      super(TYPE, EMPTY)
      @value = value
    end

    def get(name : Token) : Value
      case name.lexeme
      when "abs"
        ::Lit::Native::Fn.new(name.lexeme, 0, ->(_interpreter : Interpreter, _arguments : ::Array(Value), _token : Token) : Value {
          @value.abs
        })
      when "to_f"
        ::Lit::Native::Fn.new(name.lexeme, 0, ->(_interpreter : Interpreter, _arguments : ::Array(Value), _token : Token) : Value {
          @value.to_f
        })
      when "chr"
        ::Lit::Native::Fn.new(name.lexeme, 0, ->(_interpreter : Interpreter, _arguments : ::Array(Value), _token : Token) : Value {
          @value.chr.to_s
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
