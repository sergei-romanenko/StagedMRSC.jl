module Graphs

using StagedMRSC.Misc

#
# Graphs of configurations
#
# A `Graph` is supposed to represent a residual program.
# Technically, a `Graph` is a tree, with `back` nodes being
# references to parent nodes.
#
# A graph's nodes contain configurations. Here we abstract away
# from the concrete structure of configurations.
# In this model the arrows in the graph carry no information,
# because this information can be kept in nodes.
# (Hence, this information is supposed to be encoded inside
# "configurations".)
#
# To simplify the machinery, back-nodes in this model of
# supercompilation do not contain explicit references
# to parent nodes. Hence, `Back(c)` means that `c` is foldable
# to a parent configuration (perhaps, to several ones).
#
# * Back-nodes are produced by folding a configuration to another
#  configuration in the history.
# * Forth-nodes are produced by
#    + decomposing a configuration into a number of other configurations
#      (e.g. by driving or taking apart a let-expression), or
#    + by rewriting a configuration by another one (e.g. by generalization,
#      introducing a let-expression or applying a lemma during
#      two-level supercompilation).

export
    Graph, Back, Forth,
    LazyGraph, Empty, Stop, Build,
    unroll,
    bad_graph

# Graph

abstract type Graph{C} end

struct Back{C} <: Graph{C}
    c::C
end

struct Forth{C} <: Graph{C}
    c::C
    gs::Vector{Graph{C}}
end

function Base.show(io::IO, g::Back)
    print(io, "Back(")
    print(io, g.c)
    print(io, ")")
end

function Base.show(io::IO, g::Forth)
    print(io, "Forth(")
    print(io, g.c)
    print(io, ", [")
    Base.show_list(io, g.gs, ", ", 0)
    print(io, "])")
end

#
# Lazy graphs of configurations
#

# A `LazyGraph a` represents a finite set of graphs
# of configurations (whose type is `Graph a`).
#
# "Lazy" graphs of configurations will be produced
# by the "lazy" (staged) version of multi-result
# supercompilation.

#/ LazyGraph

abstract type LazyGraph{C} end

struct Empty{C} <: LazyGraph{C} end

struct Stop{C} <: LazyGraph{C}
    c::C
end

struct Build{C} <: LazyGraph{C}
    c::C
    lss::Vector{Vector{LazyGraph{C}}}
end

# LazyCoraph

abstract type LazyCograph{C} end

struct Empty8{C} <: LazyCograph{C} end

struct Stop8{C} <: LazyCograph{C}
    c::C
end

struct Build8{C} <: LazyCograph{C}
    c::C
    lss::Function # () -> Vector{Vector{LazyGraph{C}}}
    lss_val::Union{Vector{Vector{LazyCograph{C}}},Nothing}

    function Build8(c::C, lss::Function) where {C}
        new{C}(c, lss, nothing)
    end
end

function get_lss(g::Build8{C})::Vector{Vector{LazyGraph{C}}} where {C}
    if g.lss_val isa Nothing
        g.lss_val = g.lss()
    end
    g.lss_val
end

# The semantics of a `LazyGraph` is formally defined by
# the interpreter `unroll` that generates a sequence of `Graph` from
# the `LazyGraph` by executing commands recorded in the `LazyGraph`.

function unroll(::LazyGraph{C})::Vector{Graph{C}} where {C} end

unroll(::Empty{C}) where {C} = []

unroll(l::Stop{C}) where {C} = [Back{C}(l.c)]

function unroll(l::Build{C}) where {C}
    gss = [gs
           for ls in l.lss
           for gs in cartesian([unroll(l) for l in ls])]
    return [Forth{C}(l.c, gs) for gs in gss]
end

# Usually, we are not interested in the whole bag `unroll(l)`.
# The goal is to find "the best" or "most interesting" graphs.
# Hence, there should be developed some techniques of extracting
# useful information from a `LazyGraph` without evaluating
# `unroll(l)` directly.

# This can be formulated in the following form.
# Suppose that a function `select` filters bags of graphs,
# removing "bad" graphs, so that
#     select(unroll(l))
# generates the bag of "good" graphs.
# Let us find a function `extract` such that
#     extract(l) == select(unroll(l))
# In many cases, `extract` may be more efficient (by several orders
# of magnitude) than the composition `select . unroll`.
# Sometimes, `extract` can be formulated in terms of "cleaners" of
# lazy graphs. Let `clean` be a function that transforms lazy graphs,
# such that
#     unroll(clean(l)) ⊆ unroll(l)
# Then `extract` can be constructed in the following way:
#     extract(l) == unroll(clean(l))
# Theoretically speaking, `clean` is the result of "promoting" `select`:
#     (select compose unroll)(l) == (unroll compose clean)(l)
# The nice property of cleaners is that they are composable:
# given `clean1` and `clean2`, `clean2 compose clean1` is also a cleaner.

#
# Some filters
#

# Removing graphs that contain "bad" configurations.
# Configurations represent states of a computation process.
# Some of these states may be "bad" with respect to the problem
# that is to be solved by means of supercompilation.

function bad_graph(::Function, ::Graph{C})::Bool where {C} end

function bad_graph(bad::Function, g::Back{C})::Bool where {C}
    bad(g.c)
end

function bad_graph(bad::Function, g::Forth{C})::Bool where {C}
    bad(g.c) || any(curry(bad_graph, bad), g.gs)
end

end # Graphs
