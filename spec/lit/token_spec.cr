require "../spec_helper"

describe Lit::Token do
  describe "#inspect" do
    it "outputs a string representation" do
      token = Create.token(:number)

      token.inspect.should eq "<NUMBER lexeme: '1' literal: 1.0>"
    end

    it "omits literal when is nil" do
      token = Create.token(:left_paren)

      token.inspect.should eq "<LEFT_PAREN lexeme: '(' literal: nothing>"
    end
  end
end
