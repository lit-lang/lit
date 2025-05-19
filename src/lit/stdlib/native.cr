require "../interpreter"
require "./lit_array"
require "./lit_map"
require "./native_fn"

module Lit
  module Stdlib
    module Native
      def self.all
        [
          ::Lit::Native::Fn.new("Array", 0.., ->(_interpreter : Interpreter, arguments : ::Array(Value), _token : Token) : Value {
            if arguments.empty?
              LitArray.new
            else
              LitArray.new(arguments)
            end
          }),
          ::Lit::Native::Fn.new("Map", 0.., ->(_interpreter : Interpreter, arguments : ::Array(Value), _token : Token) : Value {
            if arguments.empty?
              LitMap.new
            else
              elements = arguments
              elements.push(nil) if elements.size.odd?
              LitMap.new(elements.each_slice(2).to_h)
            end
          }),
          ::Lit::Native::Fn.new("rand", 0, ->(_interpreter : Interpreter, _arguments : ::Array(Value), _token : Token) : Value {
            Random.rand
          }),
          ::Lit::Native::Fn.new("clock", 0, ->(_interpreter : Interpreter, _arguments : ::Array(Value), _token : Token) : Value {
            Time.local.to_unix_f
          }),
          ::Lit::Native::Fn.new("println", 0.., ->(interpreter : Interpreter, arguments : ::Array(Value), token : Token) : Value {
            if arguments.empty?
              puts
            else
              arguments.each do |arg|
                puts ::Lit.stringify_value(arg, interpreter, token)
              end
            end
          }),
          ::Lit::Native::Fn.new("print", 1.., ->(interpreter : Interpreter, arguments : ::Array(Value), token : Token) : Value {
            arguments.each do |arg|
              print ::Lit.stringify_value(arg, interpreter, token)
            end
          }),
          ::Lit::Native::Fn.new("readln", 0, ->(_interpreter : Interpreter, _arguments : ::Array(Value), _token : Token) : Value {
            gets || ""
          }),
          ::Lit::Native::Fn.new("eprint", 1, ->(interpreter : Interpreter, arguments : ::Array(Value), token : Token) : Value {
            if arguments[0].is_a?(String)
              STDERR.print(arguments[0])
            else
              raise RuntimeError.new(token, "Expected string as the first argument, got #{interpreter.type_of(arguments[0])}.")
            end
          }),
          ::Lit::Native::Fn.new("eprintln", 1, ->(interpreter : Interpreter, arguments : ::Array(Value), token : Token) : Value {
            if arguments[0].is_a?(String)
              STDERR.puts(arguments[0])
            else
              raise RuntimeError.new(token, "Expected string as the first argument, got #{interpreter.type_of(arguments[0])}.")
            end
          }),
          ::Lit::Native::Fn.new("panic", 1, ->(interpreter : Interpreter, arguments : ::Array(Value), token : Token) : Value {
            if arguments[0].is_a?(String)
              STDERR.puts(arguments[0])
              raise Interpreter::Exit.new(1)
            else
              raise RuntimeError.new(token, "Expected string as the first argument, got #{interpreter.type_of(arguments[0])}.")
            end
          }),
          ::Lit::Native::Fn.new("exit", 0..1, ->(interpreter : Interpreter, arguments : ::Array(Value), token : Token) : Value {
            if arguments.empty?
              raise Interpreter::Exit.new(0)
            elsif arguments[0].is_a?(Int64)
              raise Interpreter::Exit.new(arguments[0].as(Int64).to_i)
            else
              raise RuntimeError.new(token, "Expected number as the first argument, got #{interpreter.type_of(arguments[0])}.")
            end
          }),
          ::Lit::Native::Fn.new("open", 1, ->(interpreter : Interpreter, arguments : ::Array(Value), token : Token) : Value {
            filename = arguments[0]

            if filename.is_a?(String)
              File.read(filename) rescue nil
            else
              raise RuntimeError.new(token, "Expected string as the first argument, got #{interpreter.type_of(filename)}.")
            end
          }),
          ::Lit::Native::Fn.new("open!", 1, ->(interpreter : Interpreter, arguments : ::Array(Value), token : Token) : Value {
            filename = arguments[0]

            if filename.is_a?(String)
              begin
                File.read(filename)
              rescue File::NotFoundError
                raise RuntimeError.new(token, "File not found: #{filename}")
              rescue IO::Error
                raise RuntimeError.new(token, "Unable to read file: #{filename}")
              end
            else
              raise RuntimeError.new(token, "Expected string as the first argument, got #{interpreter.type_of(filename)}.")
            end
          }),
          ::Lit::Native::Fn.new("typeof", 1, ->(interpreter : Interpreter, arguments : ::Array(Value), _token : Token) : Value {
            interpreter.type_of(arguments[0])
          }),
          ::Lit::Native::Fn.new("inspect", 1, ->(interpreter : Interpreter, arguments : ::Array(Value), token : Token) : Value {
            ::Lit.inspect_value(arguments[0], interpreter, token)
          }),
          ::Lit::Native::Fn.new("sleep", 1, ->(interpreter : Interpreter, arguments : ::Array(Value), token : Token) : Value {
            seconds = arguments[0]

            if seconds.is_a?(Number)
              sleep(Time::Span.new(nanoseconds: (seconds * 1_000_000_000).to_i64))
              seconds
            else
              raise RuntimeError.new(token, "Expected number as the first argument, got #{interpreter.type_of(seconds)}.")
            end
          }),
          ::Lit::Native::Fn.new("measure", 1, ->(interpreter : Interpreter, arguments : ::Array(Value), token : Token) : Value {
            fn = arguments[0]
            if fn.is_a?(Function)
              start = Time.monotonic
              fn.call(interpreter, [] of Value, token)
              end_time = Time.monotonic

              (end_time - start).to_f
            else
              raise RuntimeError.new(token, "Expected Function as the first argument, got #{interpreter.type_of(fn)}.")
            end
          }),
          ::Lit::Native::Fn.new("argv", 0, ->(interpreter : Interpreter, _arguments : ::Array(Value), _token : Token) : Value {
            interpreter.argv
          }),
        ]
      end
    end
  end
end
