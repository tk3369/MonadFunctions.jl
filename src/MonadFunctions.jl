module MonadFunctions

export Just, None, just, NONE, some, fmap, cata, or_else
export Either, left, right, either, is_left, is_right

include("maybe.jl")
include("either.jl")

end # module
