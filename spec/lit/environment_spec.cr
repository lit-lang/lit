require "../spec_helper"

describe Lit::Environment, focus: true do
  describe "#define" do
    it "defines a new variable" do
      env = Lit::Environment.new
      env.values.size.should eq 0

      env.define("my_var", true)

      env.values.size.should eq 1
    end
  end

  describe "#get" do
    it "access variables by name" do
      env = Lit::Environment.new
      env.values["my_var"] = true
      var = Create.token(:identifier, "my_var")

      env.get(var).should eq true
    end
    context "when variable does not exist" do
      it "raises an error" do
        env = Lit::Environment.new
        var = Create.token(:identifier, "unknown")

        expect_raises(Lit::RuntimeError, /Undefined variable 'unknown'./) do
          env.get(var)
        end
      end
    end
  end
end
