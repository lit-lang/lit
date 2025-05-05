require "./callable"
require "./interpreter"

module Lit
  class Function < Callable
    private getter? initializer

    def initialize(@name : String?, @declaration : Expr::Function, @closure : Environment, @initializer : Bool); end

    def call(interpreter, arguments, token) : Value
      environment = Environment.new(@closure)

      @declaration.params.each_with_index do |param, index|
        environment.define(param.lexeme, arguments[index])
      end

      result = interpreter.execute_block(@declaration.body, environment, initializer?)

      if initializer?
        @closure.get_at(0, "self")
      else
        result
      end
    rescue e : Interpreter::Return
      # TODO: should all initializes return self?
      if initializer?
        @closure.get_at(0, "self")
      else
        e.value
      end
    end

    def arity
      @declaration.params.size
    end

    def bind(instance)
      environment = Environment.new(@closure)
      environment.define("self", instance)
      Function.new(@name, @declaration, environment, initializer?)
    end

    def to_s
      "<fn#{@name && " #{@name}"}>"
    end
  end
end
