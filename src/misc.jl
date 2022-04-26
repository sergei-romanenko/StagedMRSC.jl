module Misc

export CartProd, cartesian

#
# Cartesian product
#

# cartesian(xss:: Array{Array{X}}) :: Array{Array{X}} where {X}
#     [list(xs) for xs in itertools.product(*xss)]
# end

# We don't use the above implementation of `cartesian`, bеcause
# we want the last index to be the fastest to change.

struct CartProd{X}
    xss::Vector{Vector{X}}
end

function Base.length(cartProd::CartProd{X}) where {X}
    isempty(cartProd.xss) && return 0
    prod(length(xs) for xs in cartProd.xss)
end

selectByPositions(xss, p) =
    [xss[k][p[k]] for k in 1:length(xss)]

function Base.iterate(cartProd::CartProd)
    xss = cartProd.xss
    s = [length(xs) for xs in xss]
    isempty(s) && return nothing
    0 in s && return nothing
    p = [1 for _ in 1:length(s)]
    return selectByPositions(xss, p), (s, p)
end

function next_cart!(s, p)
    k = length(s)
    while true
        p[k] += 1
        p[k] <= s[k] && return true
        p[k] = 1
        k -= 1
        k == 0 && return false
    end
end

function Base.iterate(cartProd::CartProd, state)
    (s, p) = state
    next_cart!(s, p) || return nothing
    return selectByPositions(cartProd.xss, p), (s, p)
end

function cartesian(xss::Vector{Vector{X}})::Vector{Vector{X}} where {X}
    isempty(xss) && return []
    collect(CartProd(xss))
end

end
