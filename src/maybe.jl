abstract type Maybe end

struct Just{T} <: Maybe
    value::T
end

struct None <: Maybe end

const NONE = None()

"None trait - define `is_none_type` for custom none type."
is_none_type(::Any) = false 
is_none_type(::None) = true
is_none_type(::Nothing) = true

# constructors
just(x) = is_none_type(x) ? x : Just(x)
just(x::Just) = x

"""
    fmap(f, [x])
    fmap(f...)

Map function `f` over value `x`.  If `x` is wrapped then the result
will be wrapped as well.  If `x` is not provided then a curried 
function is returned.
"""
fmap
fmap(f::Function, x::Just) = Just(f(x.value))
fmap(f::Function, x) = is_none_type(x) ? x : f(x)

# curry
fmap(f::Function) = x -> fmap(f, x)

# curry over multiple functions
# fmap(f, g, h) = x -> (h ∘ g ∘ f)(x)
fmap(f::Function...) = x -> foldr(fmap, reverse(f), init = x)

"""
    or_else([x], y)

If `x` is an AbstractNone then return `y`.  Otherwise, return `x`.
If `x` is not provided, then a curried function is returned.
"""
or_else
or_else(x, y) = is_none_type(x) ? y : x
or_else(y) = x -> or_else(x, y)

"""
    cata(lf, rf, [x])

Catamorphism - Return `lf()` when x is an AbstractNone. Otherwsie, 
return `rf(x)`.  If `x` is wrapped then the result will be 
wrapped.  If `x` is not provided then a curried function is
returned.
"""
cata
cata(lf::Function, rf::Function, x::Just) = Just(rf(x.value))
cata(lf::Function, rf::Function, x) = is_none_type(x) ? lf() : rf(x)

# curry
cata(lf::Function, rf::Function) = x -> cata(lf, rf, x)
