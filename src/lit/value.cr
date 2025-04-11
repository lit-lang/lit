module Lit
  struct Uninitialized; end

  UNINITIALIZED = Uninitialized.new

  alias Value = Float64 | String | Bool | Nil | Callable | Type | Instance | Uninitialized
end
