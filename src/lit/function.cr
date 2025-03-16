require "./callable"

# require "./interpreter"

module Lit
  class Function < Callable
    def initialize(@declaration : Stmt::Function); end

    def call(interpreter, arguments) : Nil
      environment = Environment.new(interpreter.environment)

      @declaration.params.each_with_index do |param, index|
        environment.define(param.lexeme, arguments[index])
      end

      interpreter.execute_block(@declaration.body, environment)
    end

    def arity
      @declaration.params.size
    end

    def to_s
      "<fn #{@declaration.name.lexeme}>"
    end
  end
end
