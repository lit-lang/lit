require "../instance"
require "./native_fn"

module Lit
  class LitMap < Instance
    TYPE = Type.new("Map", {} of String => Function)

    getter elements : Hash(Value, Value)

    def initialize(elements = {} of Value => Value)
      super(TYPE, {} of String => Value)
      @elements = elements
    end

    def get(name : Token) : Value
      case name.lexeme
      when "get"
        ::Lit::Native::Fn.new(name.lexeme, 1, ->(_interpreter : Interpreter, arguments : ::Array(Value), _token : Token) : Value {
          index = arguments[0]

          @elements[index]?
        })
      when "set"
        ::Lit::Native::Fn.new(name.lexeme, 2, ->(_interpreter : Interpreter, arguments : ::Array(Value), _token : Token) : Value {
          index = arguments[0]
          value = arguments[1]

          @elements[index] = value
        })
      when "size"
        ::Lit::Native::Fn.new(name.lexeme, 0, ->(_interpreter : Interpreter, _arguments : ::Array(Value), _token : Token) : Value {
          @elements.size.to_i64
        })
      when "merge"
        ::Lit::Native::Fn.new(name.lexeme, 1, ->(interpreter : Interpreter, arguments : ::Array(Value), _token : Token) : Value {
          if !arguments[0].is_a?(LitMap)
            raise RuntimeError.new(name, "I was expecting a #{type.name}, but got #{interpreter.type_of(arguments[0])}.")
          end

          LitMap.new(@elements.merge(arguments[0].as(LitMap).elements))
        })
      when "is_empty?"
        ::Lit::Native::Fn.new(name.lexeme, 0, ->(_interpreter : Interpreter, _arguments : ::Array(Value), _token : Token) : Value {
          @elements.empty?
        })
      when "to_s"
        ::Lit::Native::Fn.new(name.lexeme, 0, ->(interpreter : Interpreter, _arguments : ::Array(Value), token : Token) : Value {
          return "{:}" if @elements.empty?

          "{#{@elements.map { |k, v| "#{::Lit.inspect_value(k, interpreter, token)} : #{::Lit.inspect_value(v, interpreter, token)}" }.join(", ")}}"
        })
      else
        super
      end
    end

    def set(name : Token, value : Value)
      raise RuntimeError.new(name, "Cannot set properties on #{TYPE.name}.")
    end
  end
end
