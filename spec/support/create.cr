module Create
  extend self

  def token(type : Symbol) : Lit::Token
    case type
    when :number
      Lit::Token.new(token(NUMBER), "1", 1.0, 1)
    when :left_paren
      Lit::Token.new(token(LEFT_PAREN), "(", nil, 1)
    when :right_paren
      Lit::Token.new(token(RIGHT_PAREN), ")", nil, 1)
    when :string
      Lit::Token.new(token(STRING), %("some text"), "some text", 1)
    when :false, :true, :nil
      Lit::Token.new(Lit::TokenType.parse(type.to_s), type.to_s, nil, 1)
    when :comma
      Lit::Token.new(Lit::TokenType.parse(type.to_s), ",", nil, 1)
    when :minus
      Lit::Token.new(Lit::TokenType.parse(type.to_s), "-", nil, 1)
    when :plus
      Lit::Token.new(Lit::TokenType.parse(type.to_s), "+", nil, 1)
    when :slash
      Lit::Token.new(Lit::TokenType.parse(type.to_s), "/", nil, 1)
    when :star
      Lit::Token.new(Lit::TokenType.parse(type.to_s), "*", nil, 1)
    when :eof
      Lit::Token.new(Lit::TokenType.parse(type.to_s), "", nil, 1)
    else
      if type.to_s.starts_with?("number_")
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
