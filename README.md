# MonadFunctions

[![Build Status](https://travis-ci.org/tk3369/MonadFunctions.jl.svg?branch=master)](https://travis-ci.org/tk3369/MonadFunctions.jl)
[![codecov.io](http://codecov.io/github/tk3369/MonadFunctions.jl/coverage.svg?branch=master)](http://codecov.io/github/tk3369/MonadFunctions.jl?branch=master)

This package contains functions that works with the following types of monads:

- Maybe
- Either / Result
- List

## Usage

### Maybe

The `fmap` function can map over any Maybe monad (either `Just` or `None`).
If the input is wrapped as a `Just` object, the output is automatically
wrapped as well.  `NONE` is a singleton constant of `None`.

```julia
1       |> fmap(x -> x + 1)   # 2
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

It is possible to extend to your own `Just` and `None` types by implementing the
`MaybeTypeTrait`. Note that `Nothing` is given a `IsNone` trait by default.

### Either

The `Either` type is used to capture either a left or right object. To create an
Either object, simply use the `left` or `right` function. Use `left_value`
or`right_value` to extract the wrapped value. Use `is_left` or `is_right` to
check if an object is left or right. There is no discrimination which way is
better.

A special case of `Either` is `Result`, which is used for exception handling.
Use the `result` constructor to create a `Result` object. By default, any
subtypes of `ErrorException` are considered left. Everything else is considered
right.

```julia
julia> result(1)
MonadResult_Value(1)

julia> result(ArgumentError("bad input"))
MonadResult_Error(ArgumentError("bad input"))
```

The convenient `is_left` and `is_right` functions can be used to 
check if the object is left or right.  To extract value from the
object, use `left_value` or `right_value`.

```julia
julia> is_right(result(1))
true

julia> is_left(result(ArgumentError("bad input")))
true

julia> right_value(result(1))
1

julia> left_value(result(1))
ERROR: MethodError: no method matching left_value(::Either{:R,:Result})
```

### List

A List monad is essentially a 1-dimensional array.  Use the `list` constructor to create a new list monad.  We can `fmap` over all elements, or `flatten` a nested list.

```julia
julia> m = list(1)
1-element Array{Int64,1}:
 1

julia> v = list([1,2,3])
3-element Array{Int64,1}:
 1
 2
 3

julia> fmap(x -> 2x, v)
3-element Array{Int64,1}:
 2
 4
 6

julia> flatten([1, [2,3], [[4],[5]]])
5-element Array{Int64,1}:
 1
 2
 3
 4
 5
```

## More Examples

### Using maybe monad to handle Nothing

Maybe is a monad that either contains something useful or nothing. How is it
useful? Sometimes certain functions returns `nothing` rather than throwing
exception to indicate a negative condition For example:

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

To make that happen, we can do the following to create composable functions that
only take single arguments.

```julia
Base.match(re::Regex) = Base.Fix1(match, re)
extract = rm::RegexMatch -> rm.match
concat(s::String) = Base.Fix2(string, s)
```

If you don't like type piracy then define your own `match` function or convince
the Julia core developers that it is a good addition to the Base library. And,
this would work just fine:
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

### Using result monad for exception handling

Either is a monad that contains data on the left side or right side.
It is useful to keep track of two scenarios.  For examples:

```julia
julia> going_to_party = left("I am sick")
MonadEither_Left(I am sick)

julia> is_left(going_to_party)
true

julia> play_badminton = right("this weekend")
MonadEither_Right(this weekend)

julia> is_right(play_badminton)
true

julia> right_value(play_badminton)
"this weekend"
```

`Result` is a monad that is a special case of `Either`. By convention, we stay
on the right track for normal conditions but switch to the left track when we
encounter an error condition. Once we're on the left track, we stay on the it
and ignore all computation until the end. As the error condition was captured
when we switch to the left track, we can tell what went wrong when we come out
of the computation. As you can see, Either monad is useful in handling errors.

A simple example is to run a database query. As part of the process, we need to
establish a connection, obtain a database cursor, and then run the query. The
trouble is that it may throw an exception at any of the database api calls:

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

It would be nice if the error just _flows_ to the end. Without using try-catch
statement, we would like to do this:

```julia
# anonymous function to make it composable
run_query(sql) = cursor -> query(cursor, sql)

# error handler
handle_query_result(err::LeftEither) = @error(left_value(err))

# result set handler
handle_query_result(rs::DataFrame) = "good job" 

# establish pipeline
result = fmap(
    url,
    get_connection,
    get_cursor,
    run_query("select * from sometable"),
    handle_query_result
)
```

The returned result from `run_query` is either a good value or an error. We can
find out if it's good or bad by calling `is_right` and `is_left` respectively.
If needed, we can also dispatch based upon `ResultEither` or `ErrorEither`
types.
