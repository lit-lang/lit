module Create
  extend self

  TOKENS = {
    false:         "false",
    true:          "true",
    nil:           "nil",
    and:           "and",
    or:            "or",
    left_paren:    "(",
    right_paren:   ")",
    equal_equal:   "==",
    bang_equal:    "!=",
    question:      "?",
    bang:          "!",
    comma:         ",",
    minus:         "-",
    plus:          "+",
    slash:         "/",
    star:          "*",
    percent:       "%",
    less:          "<",
    less_equal:    "<=",
    greater:       ">",
    greater_equal: ">=",
    equal:         "=",
    pipe_greater:  "|>",
    print:         "print",
    println:       "println",
    var:           "var",
    let:           "let",
    colon:         ":",
    newline:       "\n",
    eof:           "",
  }

  def token(type : Symbol, value = nil) : Lit::Token
    case type
    when :number
      Lit::Token.new(Lit::TokenType.parse(type.to_s), "1", 1.0, 1, ::Lit.current_file_name)
    when :string
      Lit::Token.new(Lit::TokenType.parse(type.to_s), %("some text"), "some text", 1, ::Lit.current_file_name)
    when :identifier
      Lit::Token.new(Lit::TokenType.parse(type.to_s), value || "my_var", nil, 1, ::Lit.current_file_name)
    when :string_interpolation
      Lit::Token.new(Lit::TokenType.parse(type.to_s), "#{value}", value, 1, ::Lit.current_file_name)
    else
      if TOKENS.has_key?(type)
        return Lit::Token.new(Lit::TokenType.parse(type.to_s), TOKENS[type], nil, 1, ::Lit.current_file_name)
      elsif type.to_s.starts_with?("number_")
        number = type.to_s.lchop("number_")

        return Lit::Token.new(token_type(NUMBER), number, number.to_f, 1, ::Lit.current_file_name)
      end

      raise "Don't know hot to build token with type '#{type}'"
    end
  end

  def tokens(*types) : Array(Lit::Token)
    types.map { |type| self.token(type) }.to_a
  end

  def expr(type : Symbol, value = nil, left : Lit::Expr? = nil, right : Lit::Expr? = nil, operator : Lit::Token? = nil) : Lit::Expr
    case type
    when :literal
      value = 1.0 if value.nil?

      Lit::Expr::Literal.new(value)
    when :grouping
      Lit::Expr::Grouping.new(expr :literal)
    when :unary
      Lit::Expr::Unary.new(operator || self.token(:minus), right || expr(:literal))
    when :binary
      Lit::Expr::Binary.new(left || expr(:literal), operator || self.token(:plus), right || expr(:literal))
    when :logical
      Lit::Expr::Logical.new(left || expr(:literal, true), operator || self.token(:and), right || expr(:literal, true))
    when :variable
      Lit::Expr::Variable.new(self.token(:identifier, "my_var"))
    when :assign
      Lit::Expr::Assign.new(self.token(:identifier, "my_var"), expr(:literal))
    when :call
      Lit::Expr::Call.new(expr(:variable), self.token(:left_paren), exprs(:literal, :literal))
    else
      raise "Don't know hot to build expression with type '#{type}'"
    end
  end

  def exprs(*types) : Array(Lit::Expr)
    types.map { |type| expr(type) }.to_a
  end

  def stmt(type : Symbol, *opts)
    case type
    when :expression
      Lit::Stmt::Expression.new(self.expr(*opts))
    else
      raise "Don't know hot to build statement with type '#{type}'"
    end
  end
end
