module MonadFunctions

export some, fmap, cata, or_else, if_nothing, if_something
export left, right, either, is_left, is_right

include("maybe.jl")
include("either.jl")

end # module
