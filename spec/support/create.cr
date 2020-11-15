module Create
  extend self

  def token(type : Symbol) : Lit::Token
    case type
    when :number
      Lit::Token.new(token(NUMBER), "1", 1.0, 1)
    when :left_paren
      Lit::Token.new(token(LEFT_PAREN), "(", nil, 1)
    when :string
      Lit::Token.new(token(STRING), %("some text"), "some text", 1)
    when :false, :true, :nil
      Lit::Token.new(Lit::TokenType.parse(type.to_s), type.to_s, nil, 1)
    else
      raise "Don't know hot to build token with type '#{type}'"
    end
  end
end
