require "./lit/lit"

module Lit
  VERSION = "0.2.0"

  def self.run(opts : Array(String) = ARGV)
    if opts.first?
      if opts.first == "-v" || opts.first == "--version"
        puts "Lit #{VERSION}"
      else
        Lit.run_file(opts.first)
      end
    else
      Lit.run_repl
    end
  end
end
