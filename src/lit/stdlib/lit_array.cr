require "../instance"
require "./native_fn"

module Lit
  class LitArray < Instance
    TYPE = Type.new("LitArray", {} of String => Function)

    getter elements

    def initialize(elements = [] of Value)
      super(TYPE, {} of String => Value)
      @elements = elements
    end

    def get(name : Token) : Value
      case name.lexeme
      when "get"
        ::Lit::Native::Fn.new(name.lexeme, 1, ->(_interpreter : Interpreter, arguments : ::Array(Value), token : Token) : Value {
          index = arguments[0]

          begin
            if index.is_a?(Float64)
              @elements[index.to_i32]
            else
              raise RuntimeError.new(token, "Expected number as the first argument.")
            end
          rescue e : IndexError
            nil
          end
        })
      when "push"
        ::Lit::Native::Fn.new(name.lexeme, 1, ->(_interpreter : Interpreter, arguments : ::Array(Value), _token : Token) : Value {
          value = arguments[0]
          @elements << value
          value
        })
      when "pop"
        ::Lit::Native::Fn.new(name.lexeme, 0, ->(_interpreter : Interpreter, _arguments : ::Array(Value), _token : Token) : Value {
          @elements.pop
        })
      when "set"
        ::Lit::Native::Fn.new(name.lexeme, 2, ->(_interpreter : Interpreter, arguments : ::Array(Value), token : Token) : Value {
          index = arguments[0]
          value = arguments[1]

          if index.is_a?(Float64)
            index = index.to_i32
            if index >= @elements.size
              @elements.concat(Array.new(index - @elements.size + 1, nil))
            end
            @elements[index] = value
          else
            raise RuntimeError.new(token, "Expected number as the first argument.")
          end
        })
      when "concat", "add"
        ::Lit::Native::Fn.new(name.lexeme, 1, ->(_interpreter : Interpreter, arguments : ::Array(Value), token : Token) : Value {
          other = arguments[0]
          if other.is_a?(LitArray)
            @elements.concat(other.elements)
          else
            raise RuntimeError.new(token, "Expected array as the first argument.")
          end
          self
        })
      when "size"
        ::Lit::Native::Fn.new(name.lexeme, 0, ->(_interpreter : Interpreter, _arguments : ::Array(Value), _token : Token) : Value {
          @elements.size.to_f
        })
      when "is_empty?"
        ::Lit::Native::Fn.new(name.lexeme, 0, ->(_interpreter : Interpreter, _arguments : ::Array(Value), _token : Token) : Value {
          @elements.empty?
        })
      when "first"
        ::Lit::Native::Fn.new(name.lexeme, 0, ->(_interpreter : Interpreter, _arguments : ::Array(Value), _token : Token) : Value {
          @elements.first?
        })
      when "each"
        ::Lit::Native::Fn.new(name.lexeme, 1, ->(interpreter : Interpreter, arguments : ::Array(Value), token : Token) : Value {
          fn = arguments[0]
          if !fn.is_a?(Function)
            raise RuntimeError.new(token, "Expected function as the first argument.")
          end
          @elements.each do |element|
            fn.call(interpreter, [element], token)
          end
        })
      when "to_s"
        ::Lit::Native::Fn.new(name.lexeme, 0, ->(interpreter : Interpreter, _arguments : ::Array(Value), token : Token) : Value {
          "[" + @elements.map { |element| ::Lit.inspect_value(element, interpreter, token) }.join(", ") + "]"
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
