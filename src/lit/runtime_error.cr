require "./token"

module Lit
  class RuntimeError < Exception
    getter token : Token

    def initialize(@token, message)
      super(message)
    end
  end
end
