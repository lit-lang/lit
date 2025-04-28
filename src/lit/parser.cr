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

      # ignore any newlines at the start of the file
      ignore_newlines
      until at_end?
        stmts.push(declaration)
        ignore_newlines # TODO: ignore or require?
      end

      stmts
    end

    private def declaration
      if check(TokenType::FN) && check_next(TokenType::IDENTIFIER)
        consume(TokenType::FN, "BUG")
        return function("function")
      end
      return var_declaration(mutable: false) if match?(TokenType::LET)
      return var_declaration(mutable: true) if match?(TokenType::VAR)
      return type_declaration if match?(TokenType::TYPE)

      statement
    rescue ParserError
      synchronize

      # NOTE: Since there's an error, return this dumb expr just to get going
      # TODO: there's no need to create a new literal every time. move to a
      # constant. Same for other fixed literals.
      Stmt::Expression.new(Expr::Literal.new("ERROR"))
    end

    private def function(kind : String)
      name = consume(TokenType::IDENTIFIER, "I was expecting a #{kind} name.")

      Stmt::Function.new(name, function_body(kind))
    end

    private def var_declaration(mutable)
      name = consume(TokenType::IDENTIFIER, "I was expecting a variable name here.")
      initializer = if match?(TokenType::EQUAL)
                      ignore_newlines
                      expression
                    else
                      Expr::Literal.new(nil)
                    end
      consume_line("I was expecting a newline after variable declaration.")

      Stmt::Var.new(name, initializer, mutable)
    end

    private def type_declaration
      # TODO: does this allow any kind of identifier be a class name? even lowercase?
      name = consume(TokenType::IDENTIFIER, "I was expecting a type name.")
      consume(TokenType::LEFT_BRACE, "I was a '{' after the type name.")
      ignore_newlines

      methods = [] of Stmt::Function

      until check(TokenType::RIGHT_BRACE) || at_end?
        match?(TokenType::FN) # optional fn before methods.
        methods << function("method")
        consume_line("I was expecting a newline after the method declaration.")
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
      if !match_line?
        value = expression

        consume_line("I was expecting a newline after the return statement.")
      end

      Stmt::Return.new(keyword, value)
    end

    private def if_statement
      condition = expression
      consume(TokenType::LEFT_BRACE, "I was expecting a '{' after the if condition.")
      ignore_newlines

      then_branch = Stmt::Block.new(block_statements)

      if match?(TokenType::ELSE)
        if match?(TokenType::IF) # else if
          else_branch = if_statement
        else
          ignore_newlines
          consume(TokenType::LEFT_BRACE, "I was expecting a '{' after the else keyword.")
          else_branch = Stmt::Block.new(block_statements)
        end
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
      ignore_newlines

      body = Stmt::Block.new(block_statements)

      Stmt::Loop.new(body)
    end

    private def break_statement
      keyword = previous
      consume_line("I was expecting a newline after the break statement.")

      Stmt::Break.new(keyword)
    end

    private def next_statement
      keyword = previous
      consume_line("I was expecting a newline after the next statement.")
      Stmt::Next.new(keyword)
    end

    private def println_statement
      token = previous
      expr = expression
      consume_line("I was expecting a newline after the println statement.")

      Stmt::Println.new(token, expr)
    end

    private def print_statement
      token = previous
      expr = expression
      consume_line("I was expecting a newline after the print statement.")

      Stmt::Print.new(token, expr)
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
      ignore_newlines

      statements = [] of Stmt

      until check(TokenType::RIGHT_BRACE) || at_end?
        statements.push(declaration)
        # consume_line("I was expecting a newline after the statement.")
        ignore_newlines # TODO: ignore or require?
      end

      ignore_newlines
      consume(TokenType::RIGHT_BRACE, "I was expecting a '}' to close the block.")

      statements
    end

    private def expression_statement
      expr = expression
      consume_line("I was expecting a newline after the expression.")

      Stmt::Expression.new(expr)
    end

    private def expression
      assignment
    end

    private def assignment
      expr = ternary

      if match?(TokenType::EQUAL)
        equals = previous
        ignore_newlines
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
        ignore_newlines
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
        ignore_newlines
        right = and_expr
        expr = Expr::Logical.new(expr, operator, right)
      end

      expr
    end

    private def and_expr
      expr = equality

      while match?(TokenType::AND)
        operator = previous
        ignore_newlines
        right = equality
        expr = Expr::Logical.new(expr, operator, right)
      end

      expr
    end

    private def equality
      expr = comparison

      while match?(TokenType::BANG_EQUAL, TokenType::EQUAL_EQUAL)
        operator = previous
        ignore_newlines
        right = comparison
        expr = Expr::Binary.new(expr, operator, right)
      end

      expr
    end

    private def comparison
      expr = term

      while match?(TokenType::GREATER, TokenType::GREATER_EQUAL, TokenType::LESS, TokenType::LESS_EQUAL)
        operator = previous
        ignore_newlines
        right = term
        expr = Expr::Binary.new(expr, operator, right)
      end

      expr
    end

    private def term
      expr = factor

      while match?(TokenType::PLUS, TokenType::MINUS)
        operator = previous
        ignore_newlines
        right = factor

        expr = Expr::Binary.new(expr, operator, right)
      end

      expr
    end

    private def factor
      expr = unary

      while match?(TokenType::STAR, TokenType::SLASH, TokenType::PERCENT)
        operator = previous
        ignore_newlines
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
        elsif match?(TokenType::LEFT_BRACKET)
          expr = subscript(expr)
        elsif match?(TokenType::DOT)
          ignore_newlines
          name = consume(TokenType::IDENTIFIER, "I was expecting a property name after '.'.")
          expr = Expr::Get.new(expr, name)
        else
          break
        end
      end

      expr
    end

    private def primary
      return Expr::Literal.new(false) if match?(TokenType::FALSE)
      return Expr::Literal.new(true) if match?(TokenType::TRUE)
      return Expr::Literal.new(nil) if match?(TokenType::NIL)
      return Expr::Literal.new(previous.literal) if match?(TokenType::NUMBER, TokenType::STRING)
      return Expr::Self.new(previous) if match?(TokenType::SELF)
      return Expr::Variable.new(previous) if match?(TokenType::IDENTIFIER)
      return string_interpolation if match?(TokenType::STRING_INTERPOLATION)
      return function_body("function", anonymous: true) if match?(TokenType::FN)
      return array if match?(TokenType::LEFT_BRACKET)
      return map if match?(TokenType::LEFT_BRACE)

      if match?(TokenType::LEFT_PAREN)
        ignore_newlines
        expr = expression
        ignore_newlines
        consume(TokenType::RIGHT_PAREN, "I was expecting a ')' here.")

        return Expr::Grouping.new(expr)
      end

      raise error(peek, "I was expecting an expression here.")
    end

    private def string_interpolation
      token = previous
      parts = [Expr::Literal.new(previous.literal)] of Expr

      loop do
        parts << expression
        if match?(TokenType::STRING_INTERPOLATION)
          parts << Expr::Literal.new(previous.literal)
        else
          break
        end
      end

      consume(TokenType::STRING, "I was expecting the end of string interpolation.")
      parts << Expr::Literal.new(previous.literal)

      Expr::StringInterpolation.new(parts, token)
    end

    private def function_body(kind, anonymous = false)
      if anonymous
        consume(TokenType::LEFT_BRACE, "I was expecting a name or '{' after the 'fn' keyword.")
      else
        consume(TokenType::LEFT_BRACE, "I was expecting a '{' after the #{kind} name.")
      end

      body, params = block_with_params

      Expr::Function.new(params, body)
    end

    private def array
      elements, _ = expression_list(TokenType::RIGHT_BRACKET, "I was expecting a ']' after the array elements.")

      Expr::ArrayLiteral.new(elements)
    end

    private def map
      if match?(TokenType::COLON) # empty map
        consume(TokenType::RIGHT_BRACE, "I was expecting a '}' to close the map.")
        return Expr::MapLiteral.new([] of Tuple(Expr, Expr))
      end

      elements = [] of Tuple(Expr, Expr)

      loop do
        ignore_newlines
        key = expression
        consume(TokenType::COLON, "I was expecting a ':' after a map key.")
        value = expression
        ignore_newlines

        elements << {key, value}

        break if !match?(TokenType::COMMA)
        ignore_newlines
        # Allow trailing comma by checking if we're at the end of the map
        break if check(TokenType::RIGHT_BRACE)
      end

      consume(TokenType::RIGHT_BRACE, "I was expecting a '}' to close the map.")

      Expr::MapLiteral.new(elements)
    end

    private def finish_call(callee)
      ignore_newlines
      arguments, paren = expression_list(TokenType::RIGHT_PAREN, "I was expecting a ')' after the arguments.")

      Expr::Call.new(callee, paren, arguments)
    end

    private def subscript(callee)
      opening_bracket = previous
      arguments, closing_bracket = expression_list(TokenType::RIGHT_BRACKET, "I was expecting a ']' after the arguments.")

      if match?(TokenType::EQUAL)
        token = previous
        value = expression

        arguments.push(value)
        get_expr = Expr::Get.new(callee, token.with_lexeme("set"))
      else
        get_expr = Expr::Get.new(callee, opening_bracket.with_lexeme("get"))
      end

      Expr::Call.new(get_expr, closing_bracket, arguments)
    end

    private def expression_list(closed_by : TokenType, msg)
      ignore_newlines

      exprs = [] of Expr

      if !check(closed_by)
        loop do
          exprs.push(expression)

          break unless match?(TokenType::COMMA)
        end
      end

      ignore_newlines
      closing_token = consume(closed_by, msg)

      {exprs, closing_token}
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

    private def check_next(type : TokenType)
      return false if at_end?

      next_token = tokens[current + 1]
      return false if next_token.type.eof?

      next_token.type == type
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

    private def consume_line(msg)
      consume(TokenType::NEWLINE, msg)
      ignore_newlines
    end

    private def match_line? : Bool
      return false if !check(TokenType::NEWLINE)

      while match?(TokenType::NEWLINE); end
      true
    end

    private def ignore_newlines : Nil
      match_line?
    end

    private def error(token, msg)
      Lit.error(token, msg)

      ParserError.new
    end

    private def synchronize
      advance

      until at_end?
        # return if previous.type == TokenType::NEWLINE

        case peek.type
        when TokenType::VAR, TokenType::IF, TokenType::PRINTLN, TokenType::PRINT,
             TokenType::RETURN, TokenType::WHILE, TokenType::UNTIL, TokenType::BREAK,
             TokenType::LOOP, TokenType::TYPE, TokenType::FN
          return
        end

        advance
      end
    end
  end
end
