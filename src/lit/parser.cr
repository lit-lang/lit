require "./token"
require "./token_type"
require "./expr"
require "./stmt"

module Lit
  class Parser
    class ParserError < Exception; end

    getter tokens : Array(Token)
    getter current : Int32 = 0
    private property errors = [] of Tuple(Token, String)

    @block_has_explicit_params : Bool = false
    @default_param : Token? = nil

    def initialize(@tokens, @error_reporter : ErrorReporter); end

    def self.parse(tokens)
      new(tokens, ErrorReporter.new).parse
    end

    def parse : Array(Stmt)
      stmts = [] of Stmt

      # ignore any newlines at the start of the file
      ignore_newlines
      until at_end?
        stmts.push(declaration)
        ignore_newlines # TODO: ignore or require?
      end

      report_errors

      stmts
    end

    def declaration
      if match?(TokenType::IMPORT)
        path = consume(TokenType::STRING, "I was expecting a path string after the import keyword.")
        consume_line("I was expecting a newline after the import statement.")

        return Stmt::Expression.new(Expr::Import.new(path))
      end

      declaration!
    rescue ParserError
      synchronize

      # NOTE: Since there's an error, return this dumb expr just to get going
      # TODO: there's no need to create a new literal every time. move to a
      # constant. Same for other fixed literals.
      Stmt::Expression.new(Expr::Literal.new("ERROR"))
    end

    private def declaration!
      if check(TokenType::FN) && check_next(TokenType::IDENTIFIER)
        consume(TokenType::FN, "BUG")
        return function("function")
      end
      return type_declaration if match?(TokenType::TYPE)

      statement
    end

    private def function(kind : String)
      name = consume(TokenType::IDENTIFIER, "I was expecting a #{kind} name.")

      Stmt::Function.new(name, function_body(kind))
    end

    private def type_declaration
      # TODO: does this allow any kind of identifier be a class name? even lowercase?
      name = consume(TokenType::IDENTIFIER, "I was expecting a type name.")
      # I'm intentionally not allowing a do block here because it doesn't make sense
      consume(TokenType::LEFT_BRACE, "I was expecting a '{' after the type name.")
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
      expr = expression
      consume_line("I was expecting a newline after the expression.")

      Stmt::Expression.new(expr)
    end

    private def while_expr
      condition = expression
      body = block_expr("I was expecting a block after the while condition.")

      Expr::While.new(condition, body)
    end

    private def until_expr
      condition = expression
      body = block_expr("I was expecting a block after the until condition.")
      filename = previous.filename

      # desugar until to while
      Expr::While.new(Expr::Unary.new(Token.new(TokenType::BANG, "!", nil, 0, filename), condition), body)
    end

    private def loop_expr
      consume(TokenType::LEFT_BRACE, "I was expecting a '{' after the loop keyword.")
      ignore_newlines

      body = brace_block

      Expr::Loop.new(body)
    end

    private def block_with_params(error_msg)
      if match?(TokenType::LEFT_BRACE)
        params = block_params

        # It's possible just not to track default param usage if the block is
        # multi-line, but that would give a worse error message "undefined
        # variable it". I decided to track but give a proper error message when
        # using the default param inside a multi-line block.
        track_default_param_usage(params, allow_default_param: false) do
          {brace_block, params}
        end
      elsif match?(TokenType::DO)
        params = block_params

        track_default_param_usage(params, allow_default_param: true) do
          {do_block, params}
        end
      else
        raise error(peek, error_msg)
      end
    end

    private def block_expr(error_msg)
      if match?(TokenType::LEFT_BRACE)
        brace_block
      elsif match?(TokenType::DO)
        do_block
      else
        raise error(peek, error_msg)
      end
    end

    private def brace_block
      ignore_newlines

      statements = [] of Stmt

      until check(TokenType::RIGHT_BRACE) || at_end?
        statements.push(declaration)
        ignore_newlines
      end

      ignore_newlines
      consume(TokenType::RIGHT_BRACE, "I was expecting a '}' to close the block.")

      Expr::Block.new(statements)
    end

    private def block_params
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

      params
    end

    private def track_default_param_usage(params : Array(Token), allow_default_param : Bool, &)
      old_explicit = @block_has_explicit_params
      old_default_param = @default_param

      @block_has_explicit_params = !params.empty?
      @default_param = nil

      begin
        block_body, params = yield

        if @default_param && !allow_default_param
          raise error(@default_param.not_nil!, "Default parameter can't be used with multi-line blocks.")
        elsif @default_param && @block_has_explicit_params
          raise error(@default_param.not_nil!, "Default parameter can't be used when explicit parameters are defined.")
        elsif @default_param && !@block_has_explicit_params
          # Inject implicit `it`
          return {block_body, [Token.new(TokenType::IDENTIFIER, "it", nil, peek.line, peek.filename)]}
        end

        {block_body, params}
      ensure
        @block_has_explicit_params = old_explicit
        @default_param = old_default_param
      end
    end

    private def expression
      if match?(TokenType::NEXT)
        Expr::Next.new(previous)
      elsif match?(TokenType::BREAK)
        token = previous
        value = check(TokenType::NEWLINE) ? nil : expression

        Expr::Break.new(token, value)
      elsif match?(TokenType::RETURN)
        token = previous
        value = check(TokenType::NEWLINE) ? nil : expression

        Expr::Return.new(token, value)
      elsif match?(TokenType::LET, TokenType::VAR)
        var_declaration(mutable: previous.type != TokenType::LET)
      else
        assignment
      end
    end

    private def var_declaration(mutable)
      name = consume(TokenType::IDENTIFIER, "I was expecting a variable name here.")
      initializer = if match?(TokenType::EQUAL)
                      ignore_newlines
                      expression
                    else
                      Expr::Literal.new(nil)
                    end
      # consume_line("I was expecting a newline after variable declaration.")

      Expr::Var.new(name, initializer, mutable)
    end

    private def assignment
      expr = control_flow

      if match?(TokenType::EQUAL,
           TokenType::PLUS_EQUAL,
           TokenType::MINUS_EQUAL,
           TokenType::STAR_EQUAL,
           TokenType::SLASH_EQUAL,
           TokenType::PERCENT_EQUAL)
        op = previous
        ignore_newlines
        rhs = assignment

        case expr
        when Expr::Variable, Expr::Get
          if op.type != TokenType::EQUAL # Desugar augmented assignment operators
            bin_op = augmented_binary_operator_for(op)
            rhs = Expr::Binary.new(expr, op.with_type(bin_op), rhs)
          end

          return case expr
          in Expr::Variable
            Expr::Assign.new(expr.name, rhs)
          in Expr::Get
            Expr::Set.new(expr.object, expr.name, rhs)
          end
        else
          raise error(op, "Invalid assignment target.")
        end
      end

      expr
    end

    private def control_flow
      if match?(TokenType::IF)
        if_expr
      elsif match?(TokenType::MATCH)
        match_expr
      elsif match?(TokenType::WHILE)
        while_expr
      elsif match?(TokenType::UNTIL)
        until_expr
      elsif match?(TokenType::LOOP)
        loop_expr
      else
        pipeline_expr
      end
    end

    private def if_expr
      condition = expression
      then_branch = block_expr(error_msg: "I was expecting a block after the if condition.")

      # We're currently requiring else to be in the same line as token that
      # closes the if block.
      if match?(TokenType::ELSE)
        if match?(TokenType::IF) # else if
          else_branch = Expr::Block.new([
            Stmt::Expression.new(if_expr),
          ] of Stmt)
        else
          else_branch = block_expr(error_msg: "I was expecting a block after the else keyword.")
        end
      end

      Expr::If.new(condition, then_branch, else_branch) # TODO: hack to get else if to be a stmt
    end

    private def match_expr
      keyword = previous
      subject = expression
      consume(TokenType::LEFT_BRACE, "I was expecting a '{' after the match subject.")
      ignore_newlines
      if match?(TokenType::RIGHT_BRACE) # Empty match block
        raise error(previous, "I was expecting a match case after the '{'.")
      end

      branches = [] of Tuple(Expr, Expr)

      until check(TokenType::RIGHT_BRACE) || at_end?
        patterns = [expression] of Expr
        while match?(TokenType::COMMA)
          ignore_newlines
          # Allow trailing comma by checking if we're at the end of the match block
          break if check(TokenType::THEN)
          patterns << expression
        end

        consume(TokenType::THEN, "I was expecting 'then' after the match pattern.")

        body = expression
        branches += patterns.map { |p| {p, body}.as(Tuple(Expr, Expr)) }
        consume_line("I was expecting a newline after the match case.")

        ignore_newlines
        break if match?(TokenType::RIGHT_BRACE)
      end

      Expr::Match.new(keyword, subject, branches)
    end

    private def pipeline_expr
      expr = or_expr

      while match?(TokenType::PIPE_GREATER)
        operator = previous
        ignore_newlines
        right = call

        if !right.is_a? Expr::Call
          raise error(operator, "I was expecting a function call after the pipeline operator.")
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
        elsif match?(TokenType::AMPERSAND_DOT)
          token = previous
          ignore_newlines
          name = consume(TokenType::IDENTIFIER, "I was expecting a property name after '&.'.")
          # # Desugar a&.b into: if a != nil then a.b else nil
          condition = Expr::Binary.new(expr, token.with_type(TokenType::BANG_EQUAL), Expr::Literal.new(nil))
          expr = Expr::If.new(condition, then_branch: Expr::Get.new(expr, name), else_branch: Expr::Literal.new(nil))
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
      if match?(TokenType::IDENTIFIER)
        if previous.lexeme == "it"
          @default_param = previous
        end
        return Expr::Variable.new(previous)
      end
      return string_interpolation if match?(TokenType::STRING_INTERPOLATION)
      return function_body("function", anonymous: true) if match?(TokenType::FN)
      return array if match?(TokenType::LEFT_BRACKET)
      return brace_block_or_map if match?(TokenType::LEFT_BRACE)
      return do_block if match?(TokenType::DO)

      if match?(TokenType::LEFT_PAREN)
        ignore_newlines
        expr = expression
        ignore_newlines
        consume(TokenType::RIGHT_PAREN, "I was expecting a ')' here.")

        return Expr::Grouping.new(expr)
      end

      raise error(peek, "I was expecting an expression here.")
    end

    private def do_block
      # There's not a reason to disallow multiple `do`s in a row, but:
      # 1. It doesn't make sense
      # 2. It is ugly =)
      raise error(previous, "Sequential do blocks are not allowed.") if match?(TokenType::DO)

      body = expression

      Expr::Block.new([Stmt::Expression.new(body)] of Stmt)
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
      error_msg = if anonymous
                    "I was expecting a name or block after the 'fn' keyword."
                  else
                    "I was expecting a block after the #{kind} name."
                  end
      body, params = block_with_params(error_msg)

      Expr::Function.new(params, body.statements)
    end

    private def array
      elements, _ = expression_list(TokenType::RIGHT_BRACKET, "I was expecting a ']' after the array elements.")

      Expr::ArrayLiteral.new(elements)
    end

    private def brace_block_or_map
      if match?(TokenType::COLON) # empty map
        consume(TokenType::RIGHT_BRACE, "I was expecting a '}' to close the map.")
        return Expr::MapLiteral.new([] of Tuple(Expr, Expr))
      end

      ignore_newlines
      if match?(TokenType::RIGHT_BRACE) # empty block
        return Expr::Block.new([] of Stmt)
      end

      # HACK: until everything is an expression, we try to parse a declaration.
      # If it fails, then it's not a block and we try to parse a map. I dislike
      # the rewinding of the parser state, but it's a good compromise for now.
      # I'll migrate everything to expressions in several steps.
      checkpoint = @current
      errors_before = @errors.dup

      begin
        decl = declaration!

        block = brace_block
        block.statements.unshift(decl)
        block
      rescue e : ParserError # if cannot parse a statement, go back and try to parse a map
        @current = checkpoint
        @errors = errors_before

        map
      end
    end

    private def map
      elements = [] of Tuple(Expr, Expr)

      loop do
        ignore_newlines
        if match?(TokenType::SYMBOL)
          key = Expr::Literal.new(previous.literal)
        else
          key = expression
          consume(TokenType::COLON, "I was expecting a ':' after a map key.")
        end
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
      exprs = [] of Expr

      if !check(closed_by)
        loop do
          ignore_newlines
          exprs.push(expression)
          ignore_newlines

          break if !match?(TokenType::COMMA)
          ignore_newlines
          # Allow trailing comma by checking if we're at the end of the list
          break if check(closed_by)
        end
      end

      ignore_newlines
      closing_token = consume(closed_by, msg)

      {exprs, closing_token}
    end

    private AUGMENTED_BINARY_OPERATORS = {
      TokenType::PLUS_EQUAL    => TokenType::PLUS,
      TokenType::MINUS_EQUAL   => TokenType::MINUS,
      TokenType::STAR_EQUAL    => TokenType::STAR,
      TokenType::SLASH_EQUAL   => TokenType::SLASH,
      TokenType::PERCENT_EQUAL => TokenType::PERCENT,
    }

    private def augmented_binary_operator_for(token)
      AUGMENTED_BINARY_OPERATORS.fetch(token.type) do
        raise error(token, "BUG: unknown augmented binary operator #{token.type.inspect}")
      end
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

    private def peek_next
      tokens[current + 1]
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
      return if at_end?

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

    private def report_errors
      @errors.each do |(token, msg)|
        @error_reporter.report_syntax_error(token, msg)
      end
    end

    private def error(token, msg)
      @errors << {token, msg}

      ParserError.new
    end

    private def synchronize
      advance

      until at_end?
        return if previous.type == TokenType::NEWLINE

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
