"""
    some(x)

Wrap `x` as a Some object, unless `x` is nothing or is already wrapped.
"""
some
some(x::Some) = x
some(x::Nothing) = nothing
some(x) = Some(x)

"""
    fmap(f, [x])
    fmap(f...)

Map function `f` over value `x`.  If `x` is wrapped then the result
will be wrapped as well.  If `x` is not provided then a curried 
function is returned.

```jldoctest
julia> 10 |> fmap(x -> x + 1) |> fmap(x -> 2x)
22

julia> 10 |> fmap(x -> x + 1, x -> 2x)
22

julia> "abc" |> fmap(x -> match(r"^a.*", x), x -> x.match ^ 2) |> or_else("wat")
"abcabc"

julia> "def" |> fmap(x -> match(r"^a.*", x), x -> x.match ^ 2) |> or_else("wat")
"wat"
```
"""
fmap
fmap(f::Function, x::Some) = some(f(something(x)))
fmap(f::Function, x::Nothing) = nothing
fmap(f::Function, x) = f(x)

# curry
fmap(f::Function) = x -> fmap(f, x)

# curry over multiple functions
# fmap(f, g, h) = x -> (h ∘ g ∘ f)(x)
fmap(f::Function...) = x -> foldr(fmap, reverse(f), init = x)

"""
    cata(lf, rf, [x])

Catamorphism - Return `lf()` when x is nothing. Otherwsie, 
return `rf(x)`.  If `x` is wrapped then the result will be 
wrapped.  If `x` is not provided then a curried function is
returned.
"""
cata
cata(lf::Function, rf::Function, x::Some) = something(x) |> rf |> some
cata(lf::Function, rf::Function, x::Nothing) = lf()
cata(lf::Function, rf::Function, x) = rf(x)

# curry
cata(lf::Function, rf::Function) = x -> cata(lf, rf, x)

"""
    or_else([x], y)

If `x` is nothing then return `y`.  Otherwise, return `x`.
If `x` is not provided, then a curried function is returned.

```jldoctest
julia> some("hello") |> or_else("world")
Some("hello")

julia> nothing |> or_else(some("world"))
Some("world")

julia> 1 |> or_else(2)
1

julia> nothing |> or_else(2)
2
```
"""
or_else
or_else(x, y) = x
or_else(::Nothing, y) = y
or_else(y) = x -> or_else(x, y)

"""
    if_nothing(f, [x])

Return `f()` if `x` is nothing.  Otherwise, return `x`.
"""
if_nothing
if_nothing(f::Function, x) = some(x)
if_nothing(f::Function, x::Nothing) = some(f())
if_nothing(f::Function) = x -> if_nothing(f, x)

"""
    if_something(f, [x])

Return `f(x)` if `x` is not nothing.  Otherwise, return nothing.
"""
if_something
if_something(f::Function, ::Nothing) = nothing
if_something(f::Function, x::Some) = f(x) |> some
if_something(f::Function) = x -> if_something(f, x)

