# MonadFunctions

This package contains functions that works with the following types of monads:

- Maybe
- Either

## Usage

### Maybe

The `fmap` function can map over any Maybe monad (either `Just` or `None`).
If the input is wrapped as a `Just` object, the output is automatically
wrapped as well.  `NONE` is a singleton constant of `None`.

```julia
1 |> fmap(x -> x + 1)         # 2
just(1) |> fmap(x -> x + 1)   # Just(2)
NONE    |> fmap(x -> x + 1)   # NONE
```

Use `or_else` to switch over to a useful value when `NONE` is encountered.

```julia
1        |> or_else(2)        # 1
just(1)  |> or_else(2)        # Just(1)
NONE     |> or_else(2)        # 2
```

Use `cata` to execute either left function when the value is nothing or 
the right function when the value is something useful.

```julia
1        |> cata(() -> 0, x -> x + 1)     # 2
NONE     |> cata(() -> 0, x -> x + 1)     # 0
```

It is possible to extend to your own `Just` and `None` types by implementing
the `MaybeTypeTrait`.  Note that `Nothing` is given a `IsNone` trait by default.

### Either

The `Either` type is used to capture either a left or right object.
To create an Either object, simply use the `either` function.  By default,
an argument of type `Nothing` or any subtypes of `ErrorException` are 
considered left.  Everything else is considered right.  

```julia
julia> either(1)
Either{:R}(1)

julia> either(nothing)
Either{:L}(nothing)

julia> either(DomainError("cannot be negative"))
Either{:L}(DomainError("cannot be negative", ""))
```

The convenient `is_left` and `is_right` functions can be used to 
check if the object is left or right.  To unwrap the object, 
use `something`.

```julia
julia> is_right(either(1))
true

julia> is_left(either(DomainError("Bad value")))
true

julia> something(either(1))
1
```


## More Examples

### Maybe

Maybe is a monad that either contains something useful or nothing.  How is it useful?  Sometimes certain functions returns `nothing` rather than throwing exception to indicate a negative condition  For example:

```julia
match(r"^a.*", "hello")     # nothing
```

It is a bit unfortunate that we must test the condition before using the result:

```julia
matched = match(r"^a.*", "hello")
result = if matched !== nothing
    matched.match * " world"
else
    nothing
end
```

If we have the notion of Maybe, then we can do it in a functional style:
```julia
"hello" |> match(r"^a.*") |> extract |> concat(" world")
```

To make that happen, we can do the following to create composable functions that only take single arguments.

```julia
Base.match(re::Regex) = x::AbstractString -> match(re, x)
extract = rm::RegexMatch -> rm.match
concat(s::String) = x::AbstractString -> string(x, s)
```

If you don't like type piracy then define your own `match` function or convince the Julia core developers that it is a good addition to the Base library.  And, this would work just fine:
```julia
julia> "hello" |> match(r"^h.*") |> extract |> concat(" world")
"hello world"
```

That's close but this doesn't work for the nothing condition.
```julia
julia> "abc" |> match(r"^h.*") |> extract |> concat(" world")
ERROR: MethodError: no method matching (::getfield(Main, Symbol("##15#16")))(::Nothing)
```

With the help of `fmap` function, we can make it work:
```julia
julia> "abc" |> fmap(match(r"^h.*")) |> fmap(extract) |> fmap(concat(" world"))

julia> "abc" |> fmap(match(r"^h.*")) |> fmap(extract) |> fmap(concat(" world")) == nothing
true
```

This is getting a little long and hard to read, so we just compose the functions:
```julia
process(x) = fmap(
    match(r"^h.*"),
    extract,
    concat(" world")
)(x)
@test process("hello") == "hello world"
@test process("abc") == nothing
```

Look ma, it is just a data flow pipeline without any conditional statement.

### Either

Either is a monad that is popularized by "railway-oriented programming" (ROP).  The idea is that data can either flow to the left or right.  

By convention, we stay on the right track for normal conditions but switch to the left track when we encounter an error condition.  Once we're on the left track, we stay on the it and ignore all computation until the end.  As the error condition was captured when we switch to the left track, we can tell what went wrong when we come out of the computation. As you can see, Either monad is useful in handling errors.

A simple example is to run a database query.  As part of the process, we need to establish a connection, obtain a database cursor, and then run the query.  The trouble is that it may throw an exception at any of the database api calls:

```julia
try
    conn = get_connection(url)
    cursor = get_cursor(conn)
    sql = "select * from somehwere"
    return query(cursor, sql)
catch ex 
    @error "Unable to run query due to ex=$ex"
    rethrow(ex)
end
```

It would be nice if the error just _flows_ to the end.  Without using try-catch statement, we would like to do this:

```julia
run_query(sql) = cursor -> query(cursor, sql)

result = fmap(
    url,
    get_connection,
    get_cursor,
    run_query("select * from sometable"),
)

is_left(result) && @error "Unable to run query due to ex=$ex"

```

The returned result is be either a left object or a right object.  We can test it by using the `is_left` and `is_right` functions.  To extract the data from the object, we can just use `something`.  

