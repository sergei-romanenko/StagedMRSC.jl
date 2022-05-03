struct IntSCWorld <: ScWorld{Int} end

import StagedMRSC.BigStepSC: is_dangerous, is_foldable_to, develop

function is_dangerous(::IntSCWorld, h::History{Int})::Bool
    length(h) > 3
end

function is_foldable_to(::IntSCWorld, c1::Int, c2::Int)::Bool
    c1 == c2
end

function drive(c::Int)::Vector{Vector{Int}}
    if (c < 2)
        []
    else
        [[0, c - 1], [c - 1]]
    end
end

function rebuild(c::Int)::Vector{Vector{Int}}
    [[c + 1]]
end

function develop(::IntSCWorld, c::Int)::Vector{Vector{Int}}
    [drive(c); rebuild(c)]
end

