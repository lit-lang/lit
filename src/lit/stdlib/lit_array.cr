require "../instance"
require "./native_fn"

module Lit
  class LitArray < Instance
    TYPE = Type.new("Array", {} of String => Function)

    getter elements

    def initialize(elements = [] of Value)
      super(TYPE, {} of String => Value)
      @elements = elements
    end

    def get(name : Token) : Value
      case name.lexeme
      when "get"
        ::Lit::Native::Fn.new("get", 1, ->(_interpreter : Interpreter, arguments : ::Array(Value), token : Token) : Value {
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
        ::Lit::Native::Fn.new("push", 1, ->(_interpreter : Interpreter, arguments : ::Array(Value), _token : Token) : Value {
          value = arguments[0]
          @elements << value
          value
        })
      when "pop"
        ::Lit::Native::Fn.new("pop", 0, ->(_interpreter : Interpreter, _arguments : ::Array(Value), _token : Token) : Value {
          @elements.pop
        })
      when "set"
        ::Lit::Native::Fn.new("set", 2, ->(_interpreter : Interpreter, arguments : ::Array(Value), token : Token) : Value {
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
      when "concat"
        ::Lit::Native::Fn.new("concat", 1, ->(_interpreter : Interpreter, arguments : ::Array(Value), token : Token) : Value {
          other = arguments[0]
          if other.is_a?(LitArray)
            @elements.concat(other.elements)
          else
            raise RuntimeError.new(token, "Expected array as the first argument.")
          end
          self
        })
      when "size"
        ::Lit::Native::Fn.new("size", 0, ->(_interpreter : Interpreter, _arguments : ::Array(Value), _token : Token) : Value {
          @elements.size.to_f
        })
      else
        super
      end
    end

    def set(name : Token, value : Value)
      raise RuntimeError.new(name, "Cannot set properties on array.")
    end

    def to_s
      "[#{@elements.map { |element| ::Lit.inspect_value(element) }.join(", ")}]"
    end
  end
end
