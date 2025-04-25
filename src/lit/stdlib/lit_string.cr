require "../instance"
require "./native_fn"

module Lit
  class LitString < Instance
    TYPE  = Type.new("String", {} of String => Function)
    EMPTY = {} of String => Value

    def initialize(value = "")
      super(TYPE, EMPTY)
      @value = value.to_s
    end

    def get(name : Token) : Value
      case name.lexeme
      when "get"
        ::Lit::Native::Fn.new(name.lexeme, 1, ->(interpreter : Interpreter, arguments : ::Array(Value), token : Token) : Value {
          index = arguments[0]

          begin
            if index.is_a?(Int64)
              @value[index].to_s
            else
              raise RuntimeError.new(token, "Expected Integer as the first argument, got #{interpreter.type_of(index)}.")
            end
          rescue e : IndexError
            nil
          end
        })
      when "set"
        ::Lit::Native::Fn.new(name.lexeme, 2, ->(interpreter : Interpreter, arguments : ::Array(Value), token : Token) : Value {
          index = arguments[0]
          value = arguments[1]

          if !index.is_a?(Int64)
            raise RuntimeError.new(token, "Expected Integer as the first argument, got #{interpreter.type_of(index)}.")
          end
          if !value.is_a? String
            raise RuntimeError.new(token, "Expected string as the second argument, got #{interpreter.type_of(value)}.")
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
      when "size"
        ::Lit::Native::Fn.new(name.lexeme, 0, ->(_interpreter : Interpreter, _arguments : ::Array(Value), _token : Token) : Value {
          @value.size.to_i64
        })
      when "includes?"
        ::Lit::Native::Fn.new(name.lexeme, 1, ->(_interpreter : Interpreter, arguments : ::Array(Value), token : Token) : Value {
          other = arguments[0]
          if other.is_a?(String)
            @value.includes?(other)
          else
            raise RuntimeError.new(token, "Expected string as the first argument.")
          end
        })
      when "chars"
        ::Lit::Native::Fn.new(name.lexeme, 0, ->(_interpreter : Interpreter, _arguments : ::Array(Value), _token : Token) : Value {
          LitArray.new.tap do |a|
            @value.each_char { |char| a.elements.push(char.to_s) }
          end
        })
      when "bytes"
        ::Lit::Native::Fn.new(name.lexeme, 0, ->(_interpreter : Interpreter, _arguments : ::Array(Value), _token : Token) : Value {
          LitArray.new.tap do |a|
            @value.each_byte { |byte| a.elements.push(byte.to_i64) }
          end
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
      raise RuntimeError.new(name, "Cannot set properties on #{type.name}.")
    end
  end
end
