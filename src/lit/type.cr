require "./callable"
require "./interpreter"

module Lit
  class Type < Callable
    getter name

    def initialize(@name : String, @methods : Hash(String, Function)); end

    def call(interpreter, arguments, token) : Instance
      Instance.new(self).tap do |instance|
        if initializer = find_method("init")
          initializer.bind(instance).call(interpreter, arguments, token)
        end
      end
    end

    def find_method(name)
      @methods[name]? # TODO: might change to has_key? + []
    end

    def arity
      if initializer = find_method("init")
        initializer.arity
      else
        0
      end
    end

    def to_s
      @name
    end
  end
end
