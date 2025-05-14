## Unreleased - [Full diff](https://github.com/lit-lang/lit/compare/v0.2.0...main)

- Add basic import statement

They work similar to Ruby's `require_relative`:

```lit
import "foo" # imports foo.lit from the same directory
import "../bar" # imports bar.lit from the parent directory
```

The error messages now include the file name and line number, so you can find
the source of the error.

- Compare arrays/maps by structure

```lit
let a = [1, 2, 3]
let b = [1, 2, 3]
println a == b # true

let m = {a: 1, b: 2}
let n = {b: 2, a: 1}
println m == n # true
```

- Add symbol-string shorthand syntax for maps

```lit
let user = {
  name: "Alice",
}

# same as { "name": "Alice" }
# or even { :name : "Alice" }
```

- Allow break to return a value

```lit
let x = loop {
  break 1
}
println x # prints 1
```

- Introduce `it` as default parameter for one-line (do) blocks:

```lit
fn square do it * it

[1, 2, 3].each(fn do println(square(it))) # prints 1\n4\n9
```

It isn't allowed in multi-line blocks as I believe that hurts readability more
than helps. But if you **really** want it, there's a "hack" to do that:

```lit
["me"].each(fn do {
  println("No one can stop {it}!")
})
# prints "No one can stop me!"
```

I might remove this in the future, but for now it works.

- Make while/until/loop expressions, not statements

`while`/`until` will return the last value of the block, or `nil` if `break` is used.

`loop` always returns `nil` because `break` is required to exit the loop.

```lit
println(while false {}) # prints nil

var c = 0
println(
  while c < 2 {
    c = c + 1
    c - 1
  }
) # prints 1
```

- Add `do` keyword to define single-line blocks

```lit
if something_true do println("truthy!") # prints "truthy!"

fn log do |what| println("[LOG] {what}")
log("Success!") # expect: [LOG] Success!

# You can use it as an expression, even if it doesn't make much sense
let a = do "Hello"
println(a) # prints Hello
```

It won't work as the body of a `type` or `loop`, as those need to be multi-line
blocks.

- Prevent `break`/`next` from being used in functions inside loops:

```lit
   loop {
     fn foo {
       break
    }
    }
  ```

- Fix a bug where the interpreter state would leak between several runs (in the same process).
  - I've removed the class variables in favor of local variables, which was part of the fix.
  - For some reason this made the `Break`/`Next` exceptions not to be rescued anymore.
  I suspect this is a bug in the codegen pipeline of Crystal.

- Remove ternary operator

- Make if an expression, not statement

```lit
let value = if true {
  "lucky"
} else {
  "not lucky"
}

println(value) # lucky
```

- Make block an expression, not statement

Blocks being expressions allow us to group expressions (like parentheses) and
also will open the space not to need explicit returns in the future.

```lit
let x = {
  let a = 1;
  let b = 2;
  a + b # no need for return
}

println(x) # 3
```

- Add symbol strings

Symbol strings are just a different syntax for strings. They don't support
interpolation or escaping, but they look prettier in DSLs.

```lit
println(:hey == 'hey' && :hey == "hey") # true
println(:hey) # hey
println(:123) # 123
println(:1a2b3c) # 1a2b3c
```

- **BREAKING:** Only allow setting new fields on initializers

```lit
type Foo {
  init { |x| self.x = x; }
}

let f = Foo(1);
f.x = 2; # Ok
f.y = 3; # Runtime error: Undefined property 'y' for Foo.
```

- **BREAKING:** Make println/print functions, not keywords

This is a super breaking change, but I'm the only user, so screw it. The
functions at least support multiple arguments, so that's nice. Now you can use
them with the pipeline operator too.

```lit
println "Hello, world!" # doesn't work anymore
print("Hello", ",", " ", "world!", "\n") # works now
```

- Add -e/--eval option to CLI

This option allows you to execute some code directly from the command line. For
example:

```sh
lit -e 'println "Hello, world!"'
# Hello, world!
```

- Add array literal syntax

```lit
let a = [1, 2, 3]
println a[0] # 1
a[0] = 4
println a # [4, 2, 3]
```

- Add map literal syntax

Maps are key-value pairs (separated by a colon), also known as dictionaries or
hashes in other languages.

```lit
let user = {
  "name" : "Alice",
  "age" : 30, # trailing comma is allowed
}

println user["name"] # Alice
println {:}.size() # 0
```

## v0.2.0 - One fewer keystroke per statement | [Full diff](https://github.com/lit-lang/lit/compare/v0.1.0...v0.2.0)

- Remove required semicolon to separate statements

Look how clean it is now:

```lit
println "Hello, world!" # no semicolon needed!
```

Semicolons are still allowed, but not required.

- Treat primitives as instances

Now it's possible to call methods on primitives. For example:

```lit
println 1.odd?() # true

let s = "abc"
println s.empty?() # false
println s.size() # 3
println s.chars() # ["a", "b", "c"]
```

- Add function literals (anonymous functions)

```lit
let add = fn { |a, b| return a + b; }
println add(1, 2); # 3
```

- Allow overloading operators on custom types. Here's a list of the currently supported operators and the methods you need to implement in your type to overload them:

| Operator | Method to implement |
| --- | --- |
| unary - | neg |
| + | add |
| - | sub |
| * | mul |
| / | div |
| % | mod |
| == | eq |
| != | neq |
| < | lt |
| <= | lte |
| > | gt |
| >= | gte |
| [] | get |
| []= | set |

Check out [this example] to see how to overload operators on custom types.

[this example]: https://github.com/lit-lang/lit/blob/a90eec865a6ca1ac850dc6f6fedf8b5cd7c3d955/spec/e2e/custom_types/operator_overload.lit

- allow `else if`

```lit
if x == 1 {
  println "x is 1";
} else if x == 2 {
  println "x is 2";
} else {
  println "x is neither 1 nor 2";
}
```

- Add `Map` type

```lit
let m = Map();
m.set("a", 1);
m.set("b", 2);
println m.get("a"); # 1
println m.get("b"); # 2
println m.get("c"); # nil
println m.merge(Map("a", 2)) # Map("a" => 2, "b" => 2)
```

- Allow `fn` keyword before method definitions

```lit
type Foo {
  # this wasn't allowed before
  fn bar { println "bar"; }

  # this was allowed before and still works. I might deprecate it in the future
  baz { println "baz"; }
}
```

- Change default string representation for instances of custom types

```lit
type User {
  init { |name, age|
    self.name = name
    self.age = age
  }
}

println User("Alice", 30) # User(name: "Alice", age: 30)
```

- New stdlib functions: sleep, argv, exit, panic, eprint, eprintln, measure

## v0.1.0 - If you squint, it's Lox

Basically Lox, but with a few extra features:

### Features

- Arrays are supported

```lit
let a = Array(1, 2, 3);
println a.get(0); # 1
a.set(0, 4);
println a; # [4, 2, 3]
a.push(5);
pritnln a.size(); # 4
```

- String interpolation

```lit
let who = "world";
println "Hello, {who}!";
```

- Pipeline operator `|>`

```lit
fn double { |x| return x * 2; }
fn difference { |a, b| return a - b; }

# pipes lhs to first argument of rhs
println 10 |> double() |> difference(1); # 19
```

- The `let` keyword to create immutable bindings

```lit
let x = 1;
x = 2; # error!
```

- The `until` keyword for creating loops that run until a condition is met
- The `loop` keyword for creating infinite loops
- The `break` and `next` keywords are supported for loops

```lit
var i = 0;
loop {
  if i == 10 { break; }
  println i;
  i = i + 1;
}
```

- Nested multi-line comments

```lit
#= Multi-line comments
  #=
    can be nested
  =# still a comment
=# "not here"
```

- Numbers can have underscores in them

```lit
println 1_234_567; # 1234567
println 1_234.567; # 1234.567
println 1.234_567; # 1.234567
println 1_234.567_890; # 1234.56789
println 1_2_3; # 123
```

- A few extra native functions (`typeof`, `readln`, `open`)
- Minor syntax differences (if, while, function definitions, class definitions).

### Anti-features

No inheritance :)
