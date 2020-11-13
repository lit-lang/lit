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
    else
      raise "Uknown token type '#{type}'"
    end
  end
end
