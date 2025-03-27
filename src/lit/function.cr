require "./callable"
require "./interpreter"

module Lit
  class Function < Callable
    def initialize(@declaration : Stmt::Function, @closure : Environment); end

    def call(interpreter, arguments)
      environment = Environment.new(@closure)

      @declaration.params.each_with_index do |param, index|
        environment.define(param.lexeme, arguments[index])
      end

      interpreter.execute_block(@declaration.body, environment)
    rescue e : Interpreter::Return
      e.value
    end

    def arity
      @declaration.params.size
    end

    def to_s
      "<fn #{@declaration.name.lexeme}>"
    end
  end
end
