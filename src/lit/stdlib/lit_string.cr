require "../instance"
require "./native_fn"

module Lit
  class LitString < Instance
    TYPE  = Type.new("LitString", {} of String => Function)
    EMPTY = {} of String => Value

    def initialize(value = "")
      super(TYPE, EMPTY)
      @value = value.to_s
    end

    def get(name : Token) : Value
      case name.lexeme
      when "get"
        ::Lit::Native::Fn.new(name.lexeme, 1, ->(_interpreter : Interpreter, arguments : ::Array(Value), token : Token) : Value {
          index = arguments[0]

          begin
            if index.is_a?(Float64)
              @value[index.to_i32].to_s
            else
              raise RuntimeError.new(token, "Expected number as the first argument.")
            end
          rescue e : IndexError
            nil
          end
        })
      when "set"
        ::Lit::Native::Fn.new(name.lexeme, 2, ->(_interpreter : Interpreter, arguments : ::Array(Value), token : Token) : Value {
          index = arguments[0]
          value = arguments[1]

          if !value.is_a? String
            raise RuntimeError.new(token, "Expected string as the second argument.")
          end
          if !index.is_a?(Float64)
            raise RuntimeError.new(token, "Expected number as the first argument.")
          end

          index = index.to_i32
          if index.abs >= @value.size
            raise RuntimeError.new(token, "Index out of bounds.")
          end

          if value == ""
            @value.delete_at(index)
          else
            @value.sub(index, value.chars.first)
          end
        })
      when "add"
        ::Lit::Native::Fn.new(name.lexeme, 1, ->(_interpreter : Interpreter, arguments : ::Array(Value), token : Token) : Value {
          other = arguments[0]
          if other.is_a?(String)
            @value + other
          else
            raise RuntimeError.new(token, "Expected string as the first argument.")
          end
          self
        })
      when "size"
        ::Lit::Native::Fn.new(name.lexeme, 0, ->(_interpreter : Interpreter, _arguments : ::Array(Value), _token : Token) : Value {
          @value.size.to_f
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
