require "../spec_helper"

describe Lit::Token do
  describe "#inspect" do
    it "outputs a string representation" do
      token = Create.token(:number)

      token.inspect.should eq "<NUMBER '1': 1.0>"
    end

    it "omits literal when is nil" do
      token = Create.token(:left_paren)

      token.inspect.should eq "<LEFT_PAREN '('>"
    end
  end
end
