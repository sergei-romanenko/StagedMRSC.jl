module Graphs

export
    Graph, Back, Forth,
    LazyGraph, Empty, Stop, Build,
    unroll,
    bad_graph, fl_bad_conf, cl_empty, cl_bad_conf, cl_empty_and_bad,
    graph_size, cl_min_size

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

# Graph

abstract type Graph{C} end

mutable struct Back{C} <: Graph{C}
    c::C
end

mutable struct Forth{C} <: Graph{C}
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

Base.:(==)(::G, ::G) where {C,G<:Graph{C}} =
    false
Base.:(==)(g1::Back{C}, g2::Back{C}) where {C} =
    g1.c == g2.c
Base.:(==)(g1::Forth{C}, g2::Forth{C}) where {C} =
    g1.c == g2.c && g1.gs == g2.gs

Gs{C} = Vector{Graph{C}}

# Graph pretty printer

graph_pretty_printer(g::Back{C}, pp_conf, indent) where {C} =
    string(indent, "|__", pp_conf(g.c), "*")

function graph_pretty_printer(g::Forth{C}, pp_conf, indent) where {C}
    sb = []
    push!(sb, indent, "|__", pp_conf(g.c))
    for g in g.gs
        push!(sb, "\n  ", indent, "|")
        push!(sb, "\n", graph_pretty_printer(g, pp_conf, indent + "  "))
    end
    join(sb)
end

graph_pretty_printer(g::Graph{C}, pp_conf) where {C} =
    graph_pretty_printer(g, pp_conf, "")

#
# Lazy graphs of configurations
#

# A `LazyGraph a` represents a finite set of graphs
# of configurations (whose type is `Graph a`).
#
# "Lazy" graphs of configurations will be produced
# by the "lazy" (staged) version of multi-result
# supercompilation.

# LazyGraph

abstract type LazyGraph{C} end

mutable struct Empty{C} <: LazyGraph{C} end

mutable struct Stop{C} <: LazyGraph{C}
    c::C
end

mutable struct Build{C} <: LazyGraph{C}
    c::C
    lss::Vector{Vector{LazyGraph{C}}}
end

Base.:(==)(::L, ::L) where {C,L<:LazyGraph{C}} =
    false
Base.:(==)(::Empty{C}, ::Empty{C}) where {C} = true
Base.:(==)(l1::Stop{C}, l2::Stop{C}) where {C} =
    l1.c == l2.c
Base.:(==)(l1::Build{C}, l2::Build{C}) where {C} =
    l1.c == l2.c && l1.lss == l2.lss

LGs{C} = Vector{LazyGraph{C}}
LGss{C} = Vector{Vector{LazyGraph{C}}}

# LazyCoraph

abstract type LazyCograph{C} end

mutable struct Empty8{C} <: LazyCograph{C} end

mutable struct Stop8{C} <: LazyCograph{C}
    c::C
end

mutable struct Build8{C} <: LazyCograph{C}
    c::C
    lss::Function # () -> LGss{C}
    lss_val::Union{Vector{Vector{LazyCograph{C}}},Nothing}

    function Build8(c::C, lss::Function) where {C}
        new{C}(c, lss, nothing)
    end
end

function get_lss(g::Build8{C})::LGss{C} where {C}
    if g.lss_val isa Nothing
        g.lss_val = g.lss()
    end
    g.lss_val
end

# The semantics of a `LazyGraph` is formally defined by
# the interpreter `unroll` that generates a sequence of `Graph` from
# the `LazyGraph` by executing commands recorded in the `LazyGraph`.

# function unroll(::L)::Gs{C} where {C,L<:LazyGraph{C}} end

unroll(::Empty{C}) where {C} = Graph{C}[]

unroll(l::Stop{C}) where {C} = Graph{C}[Back{C}(l.c)]

function unroll(l::Build{C}) where {C}
    gss = Gs{C}[gs
                for ls in l.lss
                for gs in cartesian(Gs{C}[unroll(l) for l in ls])]
    return Graph{C}[Forth{C}(l.c, gs) for gs in gss]
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
    bad(g.c) || any(bad_graph(bad), g.gs)
end

bad_graph(bad) = g -> bad_graph(bad, g)

# This filter removes the graphs containing "bad" configurations.

function fl_bad_conf(bad::Function, gs::Gs{C})::Gs{C} where {C}
    [filter(bad_graph(bad), gs)]
end

#
# Some cleaners
#

# `cl_empty` removes subtrees that represent empty sets of graphs.

function cl_empty(::LazyGraph{C})::LazyGraph{C} where {C} end

cl_empty(l::Empty{C}) where {C} = l
cl_empty(l::Stop{C}) where {C} = l

function cl_empty(l::Build{C})::LazyGraph{C} where {C}
    lss1 = [ls for ls in map(cl_empty, l.lss) if !(ls isa Nothing)]
    length(lss1) == 0 ? Empty{C}() : Build{C}(l.c, lss1)
end

function cl_empty(ls::LGs{C})::Union{LGs{C},Nothing} where {C}
    ls1 = [cl_empty(l) for l in ls]
    any(l -> (l isa Empty), ls1) ? nothing : ls1
end

# Removing graphs that contain "bad" configurations.
# The cleaner `cl_bad_conf` corresponds to the filter `fl_bad_conf`.
# `cl_bad_conf` exploits the fact that "badness" is monotonic,
# in the sense that a single "bad" configuration spoils the whole
# graph.

function cl_bad_conf(::Function, l::Empty{C})::LazyGraph{C} where {C}
    l
end

function cl_bad_conf(bad::Function, l::Stop{C})::LazyGraph{C} where {C}
    bad(l.c) ? Empty{C}() : l
end

function cl_bad_conf(bad::Function, l::Build{C})::LazyGraph{C} where {C}
    if bad(l.c)
        Empty{C}()
    else
        Build{C}(l.c, [[cl_bad_conf(bad, l1) for l1 in ls] for ls in l.lss])
    end
end

cl_bad_conf(bad) = l -> cl_bad_conf(bad, l)

#
# The graph returned by `cl_bad_conf` may be cleaned by `cl_empty`.
#

cl_empty_and_bad(bad::Function, l::LazyGraph{C}) where {C} =
    cl_empty(cl_bad_conf(bad)(l))

cl_empty_and_bad(bad::Function) =
    l -> cl_empty_and_bad(bad, l)

#
# Extracting a graph of minimal size (if any).
#

function graph_size(::Graph{C})::Int where {C} end

graph_size(g::Back{C}) where {C} = 1
graph_size(g::Forth{C}) where {C} =
    1 + sum(map(graph_size, g.gs))

# Now we define a cleaner `cl_min_size` that produces a lazy graph
# representing the smallest graph (or the empty set of graphs).

# We use a trick: ∞ is represented by typemax(Int).

ILG{C} = Tuple{Int,LazyGraph{C}}
ILGs{C} = Tuple{Int,LGs{C}}

function cl_min_size(l::LazyGraph{C})::LazyGraph{C} where {C}
    (_, l1) = sel_min_size(l)
    l1
end

function sel_min_size(::LazyGraph{C})::ILG{C} where {C} end

sel_min_size(::Empty{C}) where {C} =
    (typemax(Int), Empty{C}())

sel_min_size(l::Stop{C}) where {C} =
    (1, l)

function sel_min_size(l::Build{C}) where {C}
    (k, ls) = sel_min_size2(l.lss)
    if k == typemax(Int)
        (typemax(Int), Empty{C}())
    else
        (1 + k, Build(l.c, [ls]))
    end
end

function select_min2(kx1::ILGs{C}, kx2::ILGs{C})::ILGs{C} where {C}
    kx1[1] <= kx2[1] ? kx1 : kx2
end

function sel_min_size2(lss::LGss{C})::ILGs{C} where {C}
    acc = (typemax(Int), LazyGraph{C}[])
    for ls in lss
        acc = select_min2(sel_min_size_and(ls), acc)
    end
    acc
end

function sel_min_size_and(ls::LGs{C})::ILGs{C} where {C}
    k = 0
    ls1 = []
    for l in ls
        (k1, l1) = sel_min_size(l)
        k = add_min_size(k, k1)
        push!(ls1, l1)
    end
    (k, ls1)
end

function add_min_size(x1::Int, x2::Int)::Int
    if x1 == typemax(Int) || x2 == typemax(Int)
        return typemax(Int)
    else
        return x1 + x2
    end
end

#
# `cl_min_size` is sound:
#
#  Let cl_min_size(l) == (k , l'). Then
#     unroll(l') ⊆ unroll(l)
#     k == graph_size((unroll(l')[0]))

end # Graphs
