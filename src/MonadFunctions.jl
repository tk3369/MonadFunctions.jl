module MonadFunctions

export Just, None, just, NONE, fmap, cata, or_else
export Either, left, right, either, is_left, is_right, left_value, right_value

include("maybe.jl")
include("either.jl")

end # module
