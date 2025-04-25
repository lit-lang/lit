module Lit
  struct Uninitialized; end

  UNINITIALIZED = Uninitialized.new

  alias Value = Int64 | Float64 | String | Bool | Nil | Callable | Type | Instance | Uninitialized

  def self.stringify_value(value : Value, interpreter : Interpreter, token : Token) : String
    return "nil" if value.nil?

    if value.is_a? Instance
      # if the type defines a `to_s` method, call it
      if method = value.get_method(token.with_lexeme("to_s"))
        return method.call(interpreter, [] of Value, token).to_s
      else
        # if the type doesn't define a `to_s` method, use the default implementation
        return value.to_s(interpreter, token)
      end
    end

    value.to_s
  end

  def self.inspect_value(value : Value, interpreter, token) : String
    return value.inspect if value.is_a? String
    return value.to_s(interpreter, token) if value.is_a? Instance

    stringify_value(value, interpreter, token)
  end
end
