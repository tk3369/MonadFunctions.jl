"Either{S} is a wrapper object having parameter S = `:L` or `:R`."
struct Either{S}
    value
end

const LeftEither  = Either{:L}
const RightEither = Either{:R}

# constructors

"""
    left(x)

Create a left-object with type LeftEither.
"""
left(x) = LeftEither(x)

"""
    right(x)
Create a right-object with type RightEither.
"""
right(x) = RightEither(x)

"""
    either(x)

Construct either a left-object or right-object.
Both `Exception`, `Nothing`, and `None` are considered left. 
Everything else is right.
"""
either(x) = right(x)
either(x::None) = left(x)
either(x::Nothing) = left(x)
either(x::Exception) = left(x)

"
    left_value(x::Either)
    right_value(x::Either)

Extract the left (or right) underlying value from the either object `x`.
"
left_value(x::LeftEither) = x.value
right_value(x::RightEither) = x.value

left_value(x::RightEither) = throw(ArgumentError("Unable to get left value out of a right-object."))
right_value(x::LeftEither) = throw(ArgumentError("Unable to get left value out of a left-object."))

"""
    fmap(f::Function, x::Either)

Map function `f` over the unwrapped value of `x` if x is a 
right-object.  Otherwise, return `x` as-is because it is a
left-object.
"""
fmap(f::Function, x::LeftEither) = x
fmap(f::Function, x::RightEither) = either(f(right_value(x)))

"Return true if `x` is a left-object."
is_left(x::Either{S}) where {S} = S === :L

"Return true if `x` is a right-object."
is_right(x::Either{S}) where {S} = S === :R


