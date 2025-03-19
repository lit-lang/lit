## Unreleased - If you squint, it's Lox

Basically Lox, but with a few extra features:

- Comments:
  - Single-line comments: `# This is a comment`
  - Multi-line comments: `#= This is a comment =#`
  - Multi-line comments can be nested:

```
#=
  This
  Should
  Be
  Ignored
  #= This should be ignored too =#
=#
```

- `until` loop
- The function syntax is `fn name { |args| body }`
- Variables are declared with `let`
- `println` instead of `print`
