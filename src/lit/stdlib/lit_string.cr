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
        ::Lit::Native::Fn.new(name.lexeme, 1, ->(interpreter : Interpreter, arguments : ::Array(Value), token : Token) : Value {
          other = arguments[0]
          if other.is_a?(String)
            @value.includes?(other)
          else
            raise RuntimeError.new(token, "Expected string as the first argument, got #{interpreter.type_of(other)}.")
          end
        })
      when "chars"
        ::Lit::Native::Fn.new(name.lexeme, 0, ->(_interpreter : Interpreter, _arguments : ::Array(Value), _token : Token) : Value {
          LitArray.new(@value.chars.map { |char| char.to_s.as(Value) })
        })
      when "bytes"
        ::Lit::Native::Fn.new(name.lexeme, 0, ->(_interpreter : Interpreter, _arguments : ::Array(Value), _token : Token) : Value {
          LitArray.new(@value.bytes.map { |byte| byte.to_i64.as(Value) })
        })
      when "chomp"
        ::Lit::Native::Fn.new(name.lexeme, 0, ->(_interpreter : Interpreter, _arguments : ::Array(Value), _token : Token) : Value {
          @value.chomp
        })
      when "split"
        ::Lit::Native::Fn.new(name.lexeme, 0..1, ->(interpreter : Interpreter, arguments : ::Array(Value), token : Token) : Value {
          LitArray.new.tap do |a|
            if arguments.empty?
              @value.split("").each { |char| a.elements.push(char.to_s) }
            else
              delimiter = arguments[0]
              if delimiter.is_a?(String)
                @value.split(delimiter).each { |part| a.elements.push(part.to_s) }
              else
                raise RuntimeError.new(token, "Expected string as the first argument, got #{interpreter.type_of(delimiter)}.")
              end
            end
          end
        })
      when "is_ascii_only?"
        ::Lit::Native::Fn.new(name.lexeme, 0, ->(_interpreter : Interpreter, _arguments : ::Array(Value), _token : Token) : Value {
          @value.ascii_only?
        })
      when "capitalize"
        ::Lit::Native::Fn.new(name.lexeme, 0, ->(_interpreter : Interpreter, _arguments : ::Array(Value), _token : Token) : Value {
          @value.capitalize
        })
      when "lowercase", "downcase"
        ::Lit::Native::Fn.new(name.lexeme, 0, ->(_interpreter : Interpreter, _arguments : ::Array(Value), _token : Token) : Value {
          @value.downcase
        })
      when "uppercase", "upcase"
        ::Lit::Native::Fn.new(name.lexeme, 0, ->(_interpreter : Interpreter, _arguments : ::Array(Value), _token : Token) : Value {
          @value.upcase
        })
      when "reverse"
        ::Lit::Native::Fn.new(name.lexeme, 0, ->(_interpreter : Interpreter, _arguments : ::Array(Value), _token : Token) : Value {
          @value.reverse
        })
      when "strip"
        ::Lit::Native::Fn.new(name.lexeme, 0, ->(_interpreter : Interpreter, _arguments : ::Array(Value), _token : Token) : Value {
          @value.strip
        })
      when "repeat"
        ::Lit::Native::Fn.new(name.lexeme, 1, ->(interpreter : Interpreter, arguments : ::Array(Value), token : Token) : Value {
          times = arguments[0]
          if times.is_a?(Int64)
            @value * times
          else
            raise RuntimeError.new(token, "Expected Integer as the first argument, got #{interpreter.type_of(times)}.")
          end
        })
      when "to_i"
        ::Lit::Native::Fn.new(name.lexeme, 0, ->(_interpreter : Interpreter, _arguments : ::Array(Value), _token : Token) : Value {
          @value.to_i64(strict: false) { 0_i64 }
        })
      when "to_i!"
        ::Lit::Native::Fn.new(name.lexeme, 0, ->(_interpreter : Interpreter, _arguments : ::Array(Value), token : Token) : Value {
          @value.to_i64(strict: false) do
            raise RuntimeError.new(token, "Cannot convert string to integer.")
          end
        })
      when "to_f"
        ::Lit::Native::Fn.new(name.lexeme, 0, ->(_interpreter : Interpreter, _arguments : ::Array(Value), _token : Token) : Value {
          @value.to_f64?(strict: false) || 0.0
        })
      when "to_f!"
        ::Lit::Native::Fn.new(name.lexeme, 0, ->(_interpreter : Interpreter, _arguments : ::Array(Value), token : Token) : Value {
          begin
            @value.to_f(strict: false)
          rescue
            raise RuntimeError.new(token, "Cannot convert string to float.")
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
