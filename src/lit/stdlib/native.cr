require "../interpreter"

module Lit
  module Stdlib
    module Native
      # TODO: this is not great, but I don't have time to figure out how to get
      # all the inherited Fn
      def self.all
        [
          Clock,
          ReadLn,
          Open,
          Typeof,
        ]
      end

      abstract class Fn < Callable
        def arity
          0
        end

        def to_s
          "<native fn>"
        end

        def check_arity(arguments, token)
          expected = arity
          if arguments.size != expected
            raise RuntimeError.new(token, "Expected #{expected} arguments but got #{arguments.size}.")
          end
          arguments
        end

        def self.fn_name
          name.split("::").last.downcase
        end
      end

      class Clock < Fn
        def call(interpreter, arguments, token) : Float64
          check_arity(arguments, token)
          Time.local.to_unix_f
        end
      end

      class ReadLn < Fn
        def call(interpreter, arguments, token) : String
          check_arity(arguments, token)
          gets || ""
        end
      end

      class Open < Fn
        def arity
          1
        end

        def call(interpreter, arguments, token) : String
          filename = check_arity(arguments, token).first

          if filename.is_a?(String)
            File.read(filename)
          else
            raise RuntimeError.new(token, "Expected string as the first argument.")
          end
        rescue e : File::Error
          raise RuntimeError.new(token, "Could not read file #{filename.inspect}")
        end
      end

      class Typeof < Fn
        def arity
          1
        end

        def call(interpreter, arguments, token) : String
          value = check_arity(arguments, token).first

          case value
          in Float64
            "Number"
          in String, Bool, Nil, Type, Function
            value.class.name.split("::").last
          in Instance
            value.type.name
          in Uninitialized, Callable
            raise "Bug in the interpreter: can't find type of #{value.inspect}"
          end
        end
      end
    end
  end
end
