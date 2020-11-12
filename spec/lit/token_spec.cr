require "../spec_helper"

describe Lit::Token do
  describe "#inspect" do
    it "outputs a string representation" do
      token = Lit::Token.new(token(NUMBER), "1", 1.0, 1)

      token.inspect.should eq "<NUMBER '1': 1.0>"
    end

    it "omits literal when is nil" do
      token = Lit::Token.new(token(LEFT_PAREN), "(", nil, 1)

      token.inspect.should eq "<LEFT_PAREN '('>"
    end
  end
end
