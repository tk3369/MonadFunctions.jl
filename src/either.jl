"Either{S} is a wrapper object having parameter S = `:L` or `:R`."
struct Either{S}
    value
end

# constructors

"Create a left-object with type Either{:L}."
left(x) = Either{:L}(x)

"Create a right-object with type Either{:R}."
right(x) = Either{:R}(x)

"""
    either(x)

Construct either Left or Right object.
Both `Exception` and `Nothing` are considered left, else right.
"""
either(x) = right(something(x))
either(x::Nothing) = left(nothing)
either(x::Exception) = left(x)

"
    something(x::Either)

Unwrap an Either object and return its underlying value.
"
Base.something(x::Either) = x.value

"""
    fmap(f, x::Either)

Map function `f` over the unwrapped value of `x` if x is a 
right-object.  Otherwise, return `x` as-is because it is a
left-object.
"""
fmap(f::Function, x::Either{:L}) = x
fmap(f::Function, x::Either{:R}) = either(f(something(x)))

"Return true if `x` is a left-object."
is_left(x::Either{S}) where S = S === :L

"Return true if `x` is a right-object."
is_right(x::Either{S}) where S = S === :R


