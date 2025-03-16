require "./interpreter"

module Lit
  class Clock < Callable
    def arity
      0
    end

    def call : Value
      Time.local.to_unix_f / 1000.0
    end

    def to_s
      "<native fn>"
    end
  end
end
