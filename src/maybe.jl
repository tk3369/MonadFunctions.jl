abstract type Maybe{T} end

struct Just{T} <: Maybe{T}
    value::T
end

struct None <: Maybe{Nothing} end

const NONE = None()

"""
    MaybeTypeTrait

An abstract type that for implementing your own `Just` or `None` types.
For examples:
```julia
MaybeTypeTrait(::Type{MyOwnJust}) = IsJust()
MaybeTypeTrait(::Type{MyOwnNone}) = IsNone()
```
"""
abstract type MaybeTypeTrait end

struct IsNone <: MaybeTypeTrait end
struct IsJust <: MaybeTypeTrait end
struct IsVal  <: MaybeTypeTrait end

MaybeTypeTrait(::Type{<:Any}) = IsVal()
MaybeTypeTrait(::Type{<:Just}) = IsJust()
MaybeTypeTrait(::Type{None}) = IsNone()
MaybeTypeTrait(::Type{Nothing}) = IsNone()

# constructors
just(x::T) where {T} = just(MaybeTypeTrait(T), x)
just(::IsNone, x) = x
just(::IsJust, x) = x
just(::IsVal, x) = Just(x)

"""
    fmap(f, [x])
    fmap(f...)

Map function `f` over value `x`.  If `x` is wrapped then the result
will be wrapped as well.  If `x` is not provided then a curried 
function is returned.
"""
fmap
fmap(f::Function, x::T) where {T} = fmap(MaybeTypeTrait(T), f, x)
fmap(::IsJust, f::Function, x) = Just(f(x.value))
fmap(::IsNone, f::Function, x) = x
fmap(::IsVal,  f::Function, x) = f(x)

# curry
fmap(f::Function) = x -> fmap(f, x)

# curry over multiple functions
# fmap(f, g, h) = x -> (h ∘ g ∘ f)(x)
fmap(f::Function...) = x -> foldr(fmap, reverse(f), init = x)

"""
    or_else([x], y)

If `x` is none then return `y`.  Otherwise, return `x`.
If `x` is not provided, then a curried function is returned.
"""
or_else
or_else(x::T, y) where {T} = or_else(MaybeTypeTrait(T), x, y)
or_else(::IsJust, x, y) = x
or_else(::IsNone, x, y) = y
or_else(::IsVal,  x, y) = x

# curry
or_else(y) = x -> or_else(x, y)

"""
    cata(lf, rf, [x])

Catamorphism - Return `lf()` when x is none. Otherwsie, 
return `rf(x)`.  If `x` is wrapped then the result will be 
wrapped.  If `x` is not provided then a curried function is
returned.
"""
cata
cata(lf::Function, rf::Function, x::T) where {T} = cata(MaybeTypeTrait(T), lf, rf, x)
cata(::IsJust, lf::Function, rf::Function, x) = just(rf(x.value))
cata(::IsNone, lf::Function, rf::Function, x) = lf()
cata(::IsVal,  lf::Function, rf::Function, x) = rf(x)

# curry
cata(lf::Function, rf::Function) = x -> cata(lf, rf, x)
