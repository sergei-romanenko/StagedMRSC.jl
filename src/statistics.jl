module Statistics

export length_unroll, size_unroll

#
# Counting without generation
#
#
# The main idea of staged supercompilation consists in
# replacing the analysis of residual graphs with the analysis
# of the program that generates the graphs.
#
# Gathering statistics about graphs is just a special case of
# such analysis. For example, it is possible to count the number of
# residual graphs that would be produced without actually generating
# the graphs.
#
# Technically, we can define a function `length_unroll(c)` that analyses
# lazy graphs such that
#   length_unroll(l) == length(unroll(l))

using StagedMRSC.Graphs

length_unroll(l::Empty{C}) where {C} = 0
length_unroll(l::Stop{C}) where {C} = 1

function length_unroll(l::Build{C}) where {C}
    s = 0
    for ls in l.lss
        m = 1
        for l in ls
            m *= length_unroll(l)
        end
        s += m
    end
    return s
end

#
# Counting nodes in collections of graphs
#
# Let us find a function `size_unroll(l)`, such that
#   size_unroll(l) == (unroll(l).length , unroll(l).map(graph_size).sum)
#

size_unroll(::Empty{C}) where {C} = 0, 0
size_unroll(::Stop{C}) where {C} = 1, 1

function size_unroll(l::Build{C}) where {C}
    k = 0
    n = 0
    for ls in l.lss
        k1, n1 = size_unroll_ls(ls)
        k, n = k + k1, n + k1 + n1
    end
    k, n
end

function size_unroll_ls(ls::Vector{LazyGraph{C}}) where {C}
    k = 1
    n = 0
    for l in ls
        k1, n1 = size_unroll(l)
        k, n = k * k1, k * n1 + k1 * n
    end
    return k, n
end

end
