"""
    list(x)

Create list monad, which is really just a 1-dimensional array.
"""
list(x::AbstractVector) = x
list(x::T) where T = T[x] 

# fmap of a list monad just maps over every element
fmap(f::Function, x::AbstractVector) = map(f, x)

"""
    flatten(x)

Flatten a list x.

# Example
```jldoctest
julia> flatten([1, [2,3], [4, [5], 6]])
6-element Array{Int64,1}:
 1
 2
 3
 4
 5
 6
```
"""
flatten

# dispatch by length of array - Val(0) for empty array, Val(1) otherwise
flatten(x::AbstractVector{T}) where T = flatten(lenval(x), x)

# returns singleton type
lenval(x::AbstractVector{T}) where T = length(x) == 0 ? Val(0) : Val(1)

# empty array - nothing to flatten
flatten(::Val{0}, x::AbstractVector{T}) where T = x

# non-empty array - flatten every element and combine them together
flatten(::Val{1}, x::AbstractVector{T}) where T = reduce(vcat, map(flatten, x))

# non-array - nothing to flatten
flatten(x) = x