## v0.2.0

- Remove required semicolon

- Treat primitives as instances

- Add function literals (anon functions)

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

- allow `else if`

- Allow fn keyword before method definitions

- new stdlib stuff: sleep, argv

- Change default instance representation

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
