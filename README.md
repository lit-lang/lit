<p align="center">
  <img src=".gitbook/assets/icon-circle.png">

  <h3 align="center">Lit</h3>
  <p align="center"><em>A simple scripting language</em></p>

  <p align="center">
    <a href="https://matheusrich.gitbook.io/lit/" target="_blank">
      <strong>Take a look at the Documentation &raquo</strong>
    </a>
    <br><br>
    <a href="https://matheusrich.gitbook.io/lit/faq" target="_blank">FAQ</a>
    &middot;
    <a href="https://github.com/MatheusRich/lit-vscode" target="_blank">VS Code extension</a>
    &middot;
    <a href="https://github.com/MatheusRich/lit/issues/new">Report a Problem</a>
  </p>
</p>

<hr>

> ATTENTION: This project is a work in progress! It's an experiment and by no means a
> production-ready language.

```ruby
module Factorial {
  fn of { |n|
    if n <= 1 then return 1

    n * Factorial.of(n - 1)
  }
}

if let n = readln.to_n!() {
  println "Factorial of {n} is {Factorial.of(n)}"
} else {
  println "{n} is not a valid number"
}
```

## Why?

_So, yet another scripting language. What's the deal?_

I'm primarily a Ruby developer, and I love the workflow of a scripting language!
I never felt the need for type annotations in Ruby, but I often saw instances of
`undefined method 'something' for nil` errors in production code.

I thought _"How can I get rid of this kind of error without going all the way down to full static typing?"_.
That's how Lit was born.

### Enter Lit

Lit indeed has some static typing, but it is _subtle_. Let's get back to the factorial example, in
particular this part:

```ruby
if let n = readln.to_n!() {
  println "Factorial of {n} is {Factorial.of(n)}"
} else {
  println "{n} is not a valid number"
}
```

What happens is that `readln` returns a string, and `to_n!` tries to convert it to an integer. But
what happens if the string is not a valid number? What should `"wut".to_n!()` do? I'm not sure, so
`to_n!` returns an error. The exclamation mark at the end of `to_n!` is a _type annotation_ that
means it's a _"dangerous"_ method.

If a method is marked as dangerous, we have to handle it. Here are some alternatives:

1. Provide a default value:

```rust
let n = readln.to_n!() or 0
```

2. Panic/Exit the program:

```rust
let n = readln.to_n!() or { panic "not a valid number" }
```

3. Propagate the error:

```rust
fn read_number! {
  let n = readln
  n = n.to_n!() or { return err("{n} is not a number") } # caller decides how to handle the error

  n
}
```

4. You can also use `if let` and `while let` to handle errors:

```rust
if let n = readln.to_n!() {
  println "{n} is a number"
} else {
  println "{n} is not a valid number"
}

while let n = readln.to_n!() {
  println "Yay! {n} is a number"
} else {
  println "{n} is not a valid number"
}
```

## Goals

Lit is my first attempt at language design. My goals are:

- **Be straightforward**:
  - If the same concept/syntax could be used in other parts of the language, great!
  - It is interpreted because this keeps things simpler.
- **Be functional-friendly**:
  - It has to have good function support (anonymous functions, composition, pipe operator).
  - Help with immutability.
- **Light static typing**:
  - No type annotations (in the usual sense);
  - No `undefined method 'x' for nil` errors;
  - It still has to feel like a scripting language.
- **Be pretty:**
  - I'm a Rubyist, after all. So, beautiful code matters.
  - I want to keep the language consistent, though.
- **Don't take it too serious**:
  - This is my first language, so I want it to be fun (and learn from experience);
  - Speed is not a priority.

## Installation

TODO: Write installation instructions here

## Docs

You can find the documentation [here](https://matheusrich.gitbook.io/lit/).

## Development

TODO: Write development instructions here

## Inspiration

[Ruby], of course, is my primary source of inspiration for how a scripting language should feel. Due
to my limited knowledge of creating a programming language, I went with [JavaScript]-like syntax.
There's also [Rust] and [V] sprinkled in the mix.

[Ruby]: https://www.ruby-lang.org/en/
[Rust]: https://www.rust-lang.org/
[V]: https://vlang.io/
[JavaScript]: https://developer.mozilla.org/en-US/docs/Web/JavaScript

## Acknowledgements

First and foremost, I'd like to thank Bob Nystrom for his incredible book [Crafting Interpreters],
which made it possible for me to start writing this language. If you can, please consider buying
it.

I also would like to thank all the [languages](#inspiration) that inspired me, and you for reading
my this!

[Crafting Interpreters]: https://craftinginterpreters.com/

## Contributing

1. Fork it (<https://github.com/your-github-user/lit/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
