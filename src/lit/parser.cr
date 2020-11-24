require "./token"
require "./token_type"
require "./expr"
require "./stmt"

module Lit
  class Parser
    class ParserError < Exception; end

    getter tokens : Array(Token)
    getter current : Int32 = 0

    def initialize(@tokens); end

    def self.parse(tokens)
      new(tokens).parse
    end

    def parse : Array(Stmt)
      stmts = [] of Stmt

      until at_end?
        stmts.push(declaration)
      end

      stmts
    end

    private def declaration
      return let_declaration if match?(TokenType::LET)

      statement
    rescue ParserError
      synchronize

      # NOTE: Since there's an error, return this dumb expr just to get going
      Stmt::Expression.new(Expr::Literal.new("ERROR"))
    end

    private def let_declaration
      name = consume(TokenType::IDENTIFIER, "I was expecting a variable name here.")
      initializer = match?(TokenType::EQUAL) ? expression : Expr::Literal.new(nil)
      consume(TokenType::SEMICOLON, "I was expecting a semicolon after variable declaration.")

      Stmt::Let.new(name, initializer)
    end

    private def statement
      return print_statement if match?(TokenType::PRINT)

      expression_statement
    end

    private def print_statement
      expr = expression
      consume(TokenType::SEMICOLON, "I was expecting a semicolon after the print statement.")

      Stmt::Print.new(expr)
    end

    private def expression_statement
      expr = expression
      consume(TokenType::SEMICOLON, "I was expecting a semicolon after the expression.")

      Stmt::Expression.new(expr)
    end

    private def expression
      or_expr
    end

    private def or_expr
      expr = and_expr

      while match?(TokenType::OR)
        operator = previous
        right = and_expr
        expr = Expr::Logical.new(expr, operator, right)
      end

      expr
    end

    private def and_expr
      expr = equality

      while match?(TokenType::AND)
        operator = previous
        right = equality
        expr = Expr::Logical.new(expr, operator, right)
      end

      expr
    end

    private def equality
      expr = comparison

      while match?(TokenType::BANG_EQUAL, TokenType::EQUAL_EQUAL)
        operator = previous
        right = comparison
        expr = Expr::Binary.new(expr, operator, right)
      end

      expr
    end

    private def comparison
      expr = term

      while match?(TokenType::GREATER, TokenType::GREATER_EQUAL, TokenType::LESS, TokenType::LESS_EQUAL)
        operator = previous
        right = term
        expr = Expr::Binary.new(expr, operator, right)
      end

      expr
    end

    private def term
      expr = factor

      while match?(TokenType::PLUS, TokenType::MINUS)
        operator = previous
        right = factor

        expr = Expr::Binary.new(expr, operator, right)
      end

      expr
    end

    private def factor
      expr = unary

      while match?(TokenType::STAR, TokenType::SLASH)
        operator = previous
        right = unary

        expr = Expr::Binary.new(expr, operator, right)
      end

      expr
    end

    private def unary
      if match?(TokenType::MINUS, TokenType::BANG)
        operator = previous
        right = unary

        return Expr::Unary.new(operator, right)
      end

      primary
    end

    private def primary
      return Expr::Literal.new(false) if match?(TokenType::FALSE)
      return Expr::Literal.new(true) if match?(TokenType::TRUE)
      return Expr::Literal.new(nil) if match?(TokenType::NIL)
      return Expr::Literal.new(previous.literal) if match?(TokenType::NUMBER, TokenType::STRING)
      return Expr::Variable.new(previous) if match?(TokenType::IDENTIFIER)

      if match?(TokenType::LEFT_PAREN)
        expr = expression
        consume(TokenType::RIGHT_PAREN, "I was expecting a ')' here.")

        return Expr::Grouping.new(expr)
      end

      raise error(peek, "I was expecting an expression here.")
    end

    private def match?(*types) : Bool
      types.each do |type|
        if check(type)
          advance

          return true
        end
      end

      false
    end

    private def check(type : TokenType)
      return false if at_end?

      peek.type == type
    end

    private def peek
      tokens[current]
    end

    private def previous
      tokens[current - 1]
    end

    private def advance
      @current += 1 unless at_end?

      previous
    end

    private def at_end?
      peek.type.eof?
    end

    private def consume(type, error_msg)
      return advance if check(type)

      raise error(peek, error_msg)
    end

    private def error(token, msg)
      Lit.error(token, msg)

      ParserError.new
    end

    private def synchronize
      # TODO: Make this right
      advance
    end
  end
end
