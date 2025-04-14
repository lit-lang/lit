module Lit
  struct Uninitialized; end

  UNINITIALIZED = Uninitialized.new

  alias Value = Float64 | String | Bool | Nil | Callable | Type | Instance | Uninitialized

  def self.stringify_value(value : Value) : String
    return "nil" if value.nil?
    return value.to_s.rchop(".0") if value.is_a? Float64

    value.to_s
  end

  def self.inspect_value(value : Value) : String
    return value.inspect if value.is_a? String

    stringify_value(value)
  end
end
