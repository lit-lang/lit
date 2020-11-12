# LIT lang

<!-- The logo will be a flame. Kinda like Elixir's -->

My first attempt on language design. My initial goals are:

- **Be pretty straightforward and simple**:
  - If the same concept/syntax could be used in other parts of the language, great!
  - It will be interpreted, because this should keep things simpler.
- **Be functional**:
  - I wanna see how far I can go with functions and hashes.
  - It has to have good function support (anonymous, composition, pipe operator).
  - It has to be immutable.
- **I don't know about types yet**:
  - I'll keep them out just for simplicity.
  - I'm not decided on how to handle null values.
- **Be beautiful:**
  - I'm a Rubyist, afterall. So, beautiful code matters.
  - I want to keep the language consistent, yet.
- **Don't take it too serious**:
  - This is my first language, so I want it to be fun (and learn from experience).

## Installation

TODO: Write installation instructions here

## Usage

```ruby
# Common functional approach
sum = { |l| List.head(l) + sum(List.tail(l)) }

# OO-like syntax
length = { |l| 1 + l.tail().length() }

# Ruby blocks as anonymous functions
mean = { |l| sum(l) / length(l) }

notes = [1, 2, 3]

# This
notes |> mean |> puts
# => 2

# is equivalent to
puts(mean(notes))
# => 2

# and it is equivalent to
notes.mean().puts()
# => 2

# DESIGN NOTE:
# The above expression is *not* beautiful.
# If I want to keep this oo-like call, it shouldn't require parenthesis.
# Maybe I cannot implement this in the first version.
notes.mean.puts
# => 2
```

## Grammar

<!-- program     -> declaration* EOF
declaration -> fnDecl | varDecl | statement
fnDecl      -> "fn" function;
varDecl
statement -->

primary = "true" | "false" | "nil" | NUMBER | STRING | IDENTIFIER | "(" expression ")"

## Development

TODO: Write development instructions here

## Contributing

1. Fork it (<https://github.com/your-github-user/lit/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
