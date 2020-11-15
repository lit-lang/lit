require "../spec_helper"

describe Lit::Parser, focus: true do
  it_parses :false, to_literal: false
  it_parses :true, to_literal: true
  it_parses :nil, to_literal: nil
  it_parses :number, to_literal: 1.0
  it_parses :string, to_literal: "some text"
end

private def it_parses(type : Symbol, to_literal)
  it "parses literal #{type}" do
    expr = Lit::Parser.parse([Create.token(type)])
    expr.value.should eq to_literal
  end
end
