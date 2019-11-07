"""
Either{S,T} is a wrapper object.

# Type Parameters:
- `S`: left/right indicator.  Either `:L` or `:R`.
- `T`: specific type of either (:General, :Result)

"""
struct Either{S,T}
    value
end

# Either Monad (General type)

const LeftEither  = Either{:L, T} where T
const RightEither = Either{:R, T} where T

"""
    left(x)

Create a left-object with type LeftEither.
"""
left(x) = Either{:L, :General}(x)
left(x::LeftEither) = x
left(x::RightEither) = error("Can't make a Left out of a Right!")

"""
    right(x)
Create a right-object with type RightEither.
"""
right(x) = Either{:R, :General}(x)
right(x::RightEither) = x
right(x::LeftEither) = error("Can't make a Right out of a Left!")

left_right_value_doc = """
    left_value(x::Either{:L})
    right_value(x::Either{:R})

Extract the left (or right) underlying value from the either object `x`.
"""

"$left_right_value_doc"
left_value(x::LeftEither) where T = x.value

"$left_right_value_doc"
right_value(x::RightEither) where T = x.value

"""
    fmap(f::Function, x::Either)

Map function `f` over the unwrapped value of `x`.
"""
fmap(f::Function, x::LeftEither) = left(f(left_value(x)))
fmap(f::Function, x::RightEither) = right(f(right_value(x)))

"Return true if `x` is a left-object."
is_left(x::Either{S,T}) where {S,T} = S === :L

"Return true if `x` is a right-object."
is_right(x::Either{S,T}) where {S,T} = S === :R

Base.show(io::IO, x::LeftEither) = 
    print(io, "MonadEither_Left(", left_value(x), ")")

Base.show(io::IO, x::RightEither) = 
    print(io, "MonadEither_Right(", right_value(x), ")")

# Result Monad

const ResultEither = Either{:R, :Result}
const ErrorEither = Either{:L, :Result}

"""
    result(x)

Create a Result monad, which is either a left-object or right-object.
Both `Exception`, `Nothing`, and `None` are considered left. 
Everything else is right.
"""
result(x) = ResultEither(x)
result(x::Exception) = ErrorEither(x)

fmap(f::Function, x::ResultEither) = result(f(right_value(x)))
fmap(f::Function, x::ErrorEither) = x

Base.show(io::IO, x::ResultEither) where {S} = 
    print(io, "MonadResult_Value(", right_value(x), ")")

Base.show(io::IO, x::ErrorEither) where {S} = 
    print(io, "MonadResult_Error(", left_value(x), ")")
