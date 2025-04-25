## v0.2.0

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

- Add function literals (anon functions)

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

- Change default instance representation

```lit
type User {
  init { |name, age|
    self.name = name
    self.age = age
  }
}

println User("Alice", 30) # User(name: "Alice", age: 30)
```

- New stdlib functions: sleep, argv, exit, panic, eprint, eprintln

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
