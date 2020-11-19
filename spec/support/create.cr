module Create
  extend self
  TOKENS = {
    false:       "false",
    true:        "true",
    nil:         "nil",
    left_paren:  "(",
    right_paren: ")",
    equal_equal: "==",
    bang_equal:  "!=",
    comma:       ",",
    minus:       "-",
    plus:        "+",
    slash:       "/",
    star:        "*",
    less:        "<",
    greater:     ">",
    eof:         "",
  }

  def token(type : Symbol) : Lit::Token
    case type
    when :number
      Lit::Token.new(Lit::TokenType.parse(type.to_s), "1", 1.0, 1)
    when :string
      Lit::Token.new(Lit::TokenType.parse(type.to_s), %("some text"), "some text", 1)
    else
      if TOKENS.has_key?(type)
        return Lit::Token.new(Lit::TokenType.parse(type.to_s), TOKENS[type], nil, 1)
      elsif type.to_s.starts_with?("number_")
        number = type.to_s.lchop("number_")

        return Lit::Token.new(token(NUMBER), number, number.to_f, 1)
      end

      raise "Don't know hot to build token with type '#{type}'"
    end
  end

  def tokens(*types) : Array(Lit::Token)
    types.map { |type| self.token(type) }.to_a
  end

  def expr(type : Symbol, value = nil) : Lit::Expr
    case type
    when :literal
      Lit::Expr::Literal.new(value || 1.0)
    when :grouping
      Lit::Expr::Grouping.new(expr :literal)
    when :unary
      Lit::Expr::Unary.new(self.token(:minus), expr(:literal))
    when :binary
      Lit::Expr::Binary.new(expr(:literal), self.token(:plus), expr(:literal))
    else
      raise "Don't know hot to build expression with type '#{type}'"
    end
  end
end
