<p align="center">
  <img src=".gitbook/assets/icon-circle.png">

  <h3 align="center">Lit</h3>

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

---

> ATENTION: This project is a work in progress 

This is my first attempt on language design. My initial goals are:

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
  - I want to keep the language consistent, though.
- **Don't take it too serious**:
  - This is my first language, so I want it to be fun (and learn from experience).
  - Speed is not a priority.

## Installation

TODO: Write installation instructions here

## Usage

```ruby
let fib = fn { |n|
  if (n < 2) { return n; }

  return fib(n - 1) + fib(n - 2);
}

let n = gets();

puts("The # {n} fibonacci number is {fib(n)}")
```

## Development

TODO: Write development instructions here

## Contributing

1. Fork it (<https://github.com/your-github-user/lit/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
