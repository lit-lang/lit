require "./interpreter"

module Lit
  class Clock < Callable
    def arity
      0
    end

    def call(_interpreter, _args) : Value
      Time.local.to_unix_f
    end

    def to_s
      "<native fn>"
    end
  end

    def to_s
      "<native fn>"
    end
  end
end
