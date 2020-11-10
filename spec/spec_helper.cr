require "spec"
require "../src/lit"

macro token(type)
  Lit::TokenType::{{type}}
end
