module Lit
  struct Uninitialized; end

  UNINITIALIZED = Uninitialized.new

  alias Value = Float64 | String | Bool | Nil | Callable | Type | Instance | Uninitialized

  def self.stringify_value(value : Value, interpreter : Interpreter, token : Token, inspect = false) : String
    return "nil" if value.nil?
    return value.to_s.rchop(".0") if value.is_a? Float64

    # if the type defines a `to_s` method, call it
    if value.is_a? Instance && (method = value.as(Instance).get_method(token.with_lexeme("to_s")))
      return method.call(interpreter, [] of Value, token).to_s
    end

    if value.is_a? String && inspect
      return value.inspect
    end

    value.to_s
  end

  def self.inspect_value(value : Value, interpreter, token) : String
    return value.inspect if value.is_a? String
    return value.to_s if value.is_a? Instance

    stringify_value(value, interpreter, token)
  end
end
