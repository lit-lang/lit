require "./scanner"
require "./token"

# TODO: Write documentation for `Lit`
module Lit
  VERSION = "0.1.0"

  def self.run_file(path)
    File.read(path)
  rescue
    puts "File not found!"
  end
end
