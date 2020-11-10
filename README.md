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

Initial sintax

```rb
say_hello = n -> puts("hello {n}")
sum = (a, b) -> a + b
a = 1
b = 2
c = sum(a, b)

expressions = 'yay', 'wow'
first, _ = expressions
((first == 'yay') == true) != false

expressions_with_emotion = map(expressions, exp -> exp + '!')
expressions_with_emotion = map(expressions, it + '!')

github_user_names = {
  dhh = 'David Heinemeier Hansson'
  matz = 'Yukihiro Matsumoto'
}
print(github_user_names.dhh)
# => 'David Heinemeier Hansson'

puts(github_user_names['matz'])
# => 'Yukihiro Matsumoto\n'

# for small hashes
point = {x = 1; y = 2}

Math = {
  PI = 3.14159

  pow = (n, m) -> n**m
  half = n -> n / 2

  Circle = {
    circumference = r -> 2 * PI * r
  }
}

List = {
  Empty = []
  empty? = list -> list == Empty
  head = list -> {
    if(empty?(list)) return Empty

    head, _ = list

    return head
  }
  tail = list -> {
    if(empty?(list)) return Empty
    
    _, tail = list

    return tail
  }
  length = list -> {
    if(empty?(list)) return 0

    return 1 + (list |> pop |> length)
  }
  sum = list -> {
    if(empty?(list)) return 0

    sumWithAccumulator(list, 0)
  }
  sumWithAccumulator = (list, acc) -> {
    acc + (list |> head |> sumWithAccumulator)
  }
}

# Math.Circle.circumference(r: 2)
# => 12.5663706

AdminUser = {
  admin? = true
}

Email = {
  send = (from, to) -> {# some implementation}
}

User = (_name, _email) -> {
  return {
    ...AdminUser # Composition
  
    name = _name, # constructor
    email = _email, # constructor
  
    # Methods
    say_hello = puts("Hello, I'm {_name}" )
    send_email = to -> Email.send(email, to)
  }
}

me = User('matheus', 'matheus@email.com')
me.say_hello()
# me.send_email(to: 'matz@email.com')

# Future?
# if(me.admin?) puts('What?')
# else puts('Hi, mere mortal')

me.admin? |> on(
  true = puts('What?'),
  false = puts('Hi, mere mortal')
)

Kernel = {
  times = (n, f) -> {
    if(n == 0) return 0

    f()
  
    return times(n - 1  f)
  }
}


mean = arr -> List.sum(arr) / List.length(arr)

notes = List.map([0, 0, 0], -> gets())
notes |> mean |> puts
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
