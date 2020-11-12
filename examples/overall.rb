say_hello = n -> puts("hello {n}")
say_hello = fn(n) puts("hello {n}")
say_hello = fn { |n| puts("hello {n}") }
say_hello = { |n| puts("hello {n}") }
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

(a = (1, 2, 3); b = 2)

(
  a = (1, 2, 3)
  b = 2
)


mean = arr -> List.sum(arr) / List.length(arr)
# should be equivalent to
mean = arr -> arr.sum() / arr.length()
mean(1, 2, 3) == (1, 2, 3).mean == 2

notes = List.map([0, 0, 0], -> gets())
notes |> mean |> puts

successors = map((1, 2, 3), i -> i + 1 )
successors = map((1, 2, 3), fn(i) i + 1 )
successors = map((1, 2, 3), { |i| i + 1 })
successors = map((1, 2, 3), { (i) i + 1 })

# Maybe without parens and ruby-like blocks?
(1, 2, 3).map { |i| return i + 1 }

# It would be nice to construct DSLs (i think the commas are a small compromisse)
describe 'List', {
  describe '.map', {
    it 'does something', {
      expect(List.map(1, 2, 3, { |n| n * 2 })).toEq(2, 4, 6)
      (1, 2, 3).map { |n| n * 2 }.should beEq(2, 4, 6)
    }
  }
}
