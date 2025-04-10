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
        match?(TokenType::SEMICOLON) # ignore extra semicolons
        stmts.push(declaration)
      end

      stmts
    end

    private def declaration
      return function("function") if match?(TokenType::FN)
      return let_declaration if match?(TokenType::LET)
      return type_declaration if match?(TokenType::TYPE)

      statement
    rescue ParserError
      synchronize

      # NOTE: Since there's an error, return this dumb expr just to get going
      Stmt::Expression.new(Expr::Literal.new("ERROR"))
    end

    private def function(kind : String)
      name = consume(TokenType::IDENTIFIER, "I was expecting a #{kind} name.")
      consume(TokenType::LEFT_BRACE, "I was expecting a '{' after the #{kind} name.")
      body, params = block_with_params

      Stmt::Function.new(name, params, body)
    end

    private def let_declaration
      name = consume(TokenType::IDENTIFIER, "I was expecting a variable name here.")
      initializer = match?(TokenType::EQUAL) ? expression : Expr::Literal.new(nil)
      consume(TokenType::SEMICOLON, "I was expecting a semicolon after variable declaration.")

      Stmt::Let.new(name, initializer)
    end

    private def type_declaration
      # TODO: does this allow any kind of identifier be a class name? even lowercase?
      name = consume(TokenType::IDENTIFIER, "I was expecting a type name.")
      consume(TokenType::LEFT_BRACE, "I was a '{' after the type name.")

      methods = [] of Stmt::Function

      until check(TokenType::RIGHT_BRACE) || at_end?
        methods << function("method")
      end

      consume(TokenType::RIGHT_BRACE, "I was expecting a '}' to close the type body.")

      Stmt::Type.new(name, methods)
    end

    private def statement
      return if_statement if match?(TokenType::IF)
      return while_statement if match?(TokenType::WHILE)
      return until_statement if match?(TokenType::UNTIL)
      return loop_statement if match?(TokenType::LOOP)
      return break_statement if match?(TokenType::BREAK)
      return next_statement if match?(TokenType::NEXT)
      return return_statement if match?(TokenType::RETURN)
      return println_statement if match?(TokenType::PRINTLN)
      return print_statement if match?(TokenType::PRINT)
      return Stmt::Block.new(block_statements) if match?(TokenType::LEFT_BRACE)

      expression_statement
    end

    private def return_statement
      keyword = previous
      value = nil
      if !check(TokenType::SEMICOLON)
        value = expression
      end
      consume(TokenType::SEMICOLON, "I was expecting a semicolon after the return statement.")

      Stmt::Return.new(keyword, value)
    end

    private def if_statement
      condition = expression
      consume(TokenType::LEFT_BRACE, "I was expecting a '{' after the if condition.")

      then_branch = Stmt::Block.new(block_statements)

      if match?(TokenType::ELSE)
        consume(TokenType::LEFT_BRACE, "I was expecting a '{' after the else keyword.")

        else_branch = Stmt::Block.new(block_statements)
      end

      Stmt::If.new(condition, then_branch, else_branch)
    end

    private def while_statement
      condition = expression
      consume(TokenType::LEFT_BRACE, "I was expecting a '{' after the while condition.")

      body = Stmt::Block.new(block_statements)

      Stmt::While.new(condition, body)
    end

    private def until_statement
      condition = expression
      consume(TokenType::LEFT_BRACE, "I was expecting a '{' after the until condition.")

      body = Stmt::Block.new(block_statements)

      # desugar until to while
      Stmt::While.new(Expr::Unary.new(Token.new(TokenType::BANG, "!", nil, 0), condition), body)
    end

    private def loop_statement
      consume(TokenType::LEFT_BRACE, "I was expecting a '{' after the loop keyword.")

      body = Stmt::Block.new(block_statements)

      Stmt::Loop.new(body)
    end

    private def break_statement
      keyword = previous
      # TODO: change "a semicolon" to "a ';'" on all error messages
      consume(TokenType::SEMICOLON, "I was expecting a semicolon after the break statement.")

      Stmt::Break.new(keyword)
    end

    private def next_statement
      keyword = previous
      consume(TokenType::SEMICOLON, "I was expecting a semicolon after the next statement.")
      Stmt::Next.new(keyword)
    end

    private def println_statement
      expr = expression
      consume(TokenType::SEMICOLON, "I was expecting a semicolon after the println statement.")

      Stmt::Println.new(expr)
    end

    private def print_statement
      expr = expression
      consume(TokenType::SEMICOLON, "I was expecting a semicolon after the print statement.")

      Stmt::Print.new(expr)
    end

    private def block_with_params
      params = [] of Token

      if match?(TokenType::BAR)   # begin params
        if !check(TokenType::BAR) # handle empty param list
          loop do
            params.push(consume(TokenType::IDENTIFIER, "I was expecting a parameter name."))

            break unless match?(TokenType::COMMA)
          end
        end
        consume(TokenType::BAR, "I was expecting a '|' after the parameters.")
      end

      {block_statements, params}
    end

    private def block_statements
      statements = [] of Stmt

      until check(TokenType::RIGHT_BRACE) || at_end?
        statements.push(declaration)
      end

      consume(TokenType::RIGHT_BRACE, "I was expecting a '}' to close the block.")

      statements
    end

    private def expression_statement
      expr = expression
      consume(TokenType::SEMICOLON, "I was expecting a semicolon after the expression.")

      Stmt::Expression.new(expr)
    end

    private def expression
      assignment
    end

    private def assignment
      expr = ternary

      if match?(TokenType::EQUAL)
        equals = previous
        value = assignment

        if expr.is_a? Expr::Variable
          name = expr.as(Expr::Variable).name

          return Expr::Assign.new(name, value)
        elsif expr.is_a? Expr::Get
          get = expr.as(Expr::Get)
          return Expr::Set.new(get.object, get.name, value)
        end

        error(equals, "Invalid assignment target.")
      end

      expr
    end

    private def ternary
      expr = pipeline_expr

      if match?(TokenType::QUESTION)
        question_mark = previous
        left = ternary
        consume(TokenType::COLON, "I was expecting a colon after the truthy condition on the ternary expression.")
        right = ternary

        return Expr::Ternary.new(expr, left, right, question_mark)
      end

      expr
    end

    private def pipeline_expr
      expr = or_expr

      while match?(TokenType::PIPE_GREATER)
        operator = previous
        right = call

        if !right.is_a? Expr::Call
          error(operator, "I was expecting a function call after the pipeline operator.")
        end

        expr = Expr::Binary.new(expr, operator, right)
      end

      expr
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

      while match?(TokenType::STAR, TokenType::SLASH, TokenType::PERCENT)
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

      call
    end

    private def call
      expr = primary

      loop do
        if match?(TokenType::LEFT_PAREN)
          expr = finish_call(expr)
        elsif match?(TokenType::DOT)
          name = consume(TokenType::IDENTIFIER, "I was expecting a property name after '.'.")
          expr = Expr::Get.new(expr, name)
        else
          break
        end
      end

      expr
    end

    private def finish_call(callee)
      arguments = [] of Expr

      if !check(TokenType::RIGHT_PAREN)
        loop do
          arguments.push(expression)

          break unless match?(TokenType::COMMA)
        end
      end

      paren = consume(TokenType::RIGHT_PAREN, "I was expecting a ')' after the arguments.")

      Expr::Call.new(callee, paren, arguments)
    end

    private def primary
      return Expr::Literal.new(false) if match?(TokenType::FALSE)
      return Expr::Literal.new(true) if match?(TokenType::TRUE)
      return Expr::Literal.new(nil) if match?(TokenType::NIL)
      return Expr::Literal.new(previous.literal) if match?(TokenType::NUMBER, TokenType::STRING)
      return Expr::Self.new(previous) if match?(TokenType::SELF)
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
      advance

      until at_end?
        # return if previous.type == TokenType::SEMICOLON

        case peek.type
        when TokenType::LET, TokenType::IF, TokenType::PRINTLN, TokenType::PRINT,
             TokenType::RETURN, TokenType::WHILE, TokenType::UNTIL, TokenType::BREAK,
             TokenType::LOOP, TokenType::TYPE, TokenType::FN
          return
        end

        advance
      end
    end
  end
end
