# crossing monads

# Maybe => Either
either(x::None) = left(x)

# if x is a value, return right of x.  Else, return left of y.
right(x::T, y) where {T} = right(MaybeTypeTrait(T), x, y)
right(::IsJust, x, y) = right(x.value)
right(::IsNone, x, y) = left(y)
right(::IsVal,  x, y) = right(x)

# if x is a value, return left of x.  Elwse, return right of y.
left(x::T, y) where {T} = left(MaybeTypeTrait(T), x, y)
left(::IsJust, x, y) = left(x.value)
left(::IsNone, x, y) = right(y)
left(::IsVal,  x, y) = left(x)

# Either => Maybe

just(x::LeftEither) = NONE
just(x::RightEither) = just(right_value(x))


