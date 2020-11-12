require "./lit/lit"

module Lit
  VERSION = "0.1.0"

  def self.run(opts : Array(String) = ARGV)
    if opts.first?
      Lit.run_file(opts.first)
    else
      Lit.run_repl
    end
  end
end
