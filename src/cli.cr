require "./lit"
require "./lit/formatter"

if ARGV.first? == "format"
  Lit::Formatter.format
else
  Lit.run
end
