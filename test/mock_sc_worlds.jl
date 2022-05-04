struct IntScWorld <: ScWorld{Int} end

import StagedMRSC.BigStepSC: conf_type, is_dangerous, is_foldable_to, develop

conf_type(::IntScWorld) = Int

function is_dangerous(::IntScWorld, h::History{Int})::Bool
    length(h) > 3
end

function is_foldable_to(::IntScWorld, c1::Int, c2::Int)::Bool
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

function develop(::IntScWorld, c::Int)::Vector{Vector{Int}}
    [drive(c); rebuild(c)]
end

