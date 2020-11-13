# Overall syntax

> **DESIGN NOTE:**
>
> In LIT v1.0, the syntax is not so easy on eyes as I'd like to. There's limitations in my current
> knowledge about compilers, so I'll make some compromisses. However, in v2.0, I'll (hopefully) be able to get rid of them.
>
> Check [v2.0 docs](../v2.0/syntax.md) for the syntax I'm aiming for.

## Comprimisses of v1.0:

- All statements are ended with a `;`;
- All numbers are `Float`;
- Variables are actually mutable;

# Variables

In version 1.0, LIT will require the keyword `let` for declaring variables.

```ruby
let a = 1;
# => 1

let b = 2;
# => 2

let c = a + b;
# => 3

# You can redefine variables
a = "other value";
# => "other value"
```

Using keywords as variables will cause an error:

```ruby
let if = 123
# ERROR: SOMETHING BAD HAPPENED
```

## Allowed variable names

Variable names must begin with a letter (A-Z or a-z) or underscore. After that any letter, number or ? and ! is allowed.

```ruby
let camelCase = 1
let snake_case = 2
let PascalCase = 3
let ALL_CAPS = 4
let admin? = 5
let wow! = 6
let cool_right?! = 7
let _private = 8
let sOMETHING_elSe = "really?"
```

# Numbers

# Mathematical Operations and Elementary Functions

# Strings
There's no difference between single-quoted and double-quoted strings. They both can be interpolated:

```r
let n = 42;

"N is {n}" == 'N is {n}'
# => true
```

# Functions

# Control Flow

# Types?

# Data Structures (better name)

# Modules
