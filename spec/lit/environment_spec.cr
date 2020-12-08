require "../spec_helper"

describe Lit::Environment do
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

    context "when variable is on a enclosing scope" do
      it "searches on the enclosing scope" do
        enclosing = Lit::Environment.new
        enclosing.values["my_var"] = true
        env = Lit::Environment.new(enclosing)

        var = Create.token(:identifier, "my_var")

        env.get(var).should eq true
      end
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

  describe "#assign" do
    it "changes the value of the given variable" do
      env = Lit::Environment.new
      env.values["my_var"] = true
      var = Create.token(:identifier, "my_var")

      env.assign(var, false)

      env.values["my_var"].should eq false
    end

    context "when variable is on a enclosing scope" do
      it "searches on the enclosing scope" do
        enclosing = Lit::Environment.new
        enclosing.values["my_var"] = true
        env = Lit::Environment.new(enclosing)
        var = Create.token(:identifier, "my_var")

        env.assign(var, false)

        enclosing.values["my_var"].should eq false
      end
    end

    context "when variable does not exist" do
      it "raises an error" do
        env = Lit::Environment.new
        var = Create.token(:identifier, "unknown")

        expect_raises(Lit::RuntimeError, /Undefined variable 'unknown'./) do
          env.assign(var, false)
        end
      end
    end
  end
end
