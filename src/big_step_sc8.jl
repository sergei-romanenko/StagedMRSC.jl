module BigStepSc8

export
    build_graph8, cl8_bad_conf,
    prune

#
# Lazy infinite graphs of configurations
#

# A `LazyGraph8[C]` represents a (potentially) infinite set of graphs
# of configurations (whose type is `Graph[C]`).
#
# "Lazy" infinite graphs of configurations will be produced
# by the "lazy" (staged) version of multi-result
# supercompilation.

using DataStructures
using StagedMRSC.Graphs
import StagedMRSC.BigStepSc:
    conf_type, is_foldable_to, is_dangerous, is_foldable_to_history, develop

#
# Infinite trees/graphs
# LazyGraph8
#

abstract type LazyGraph8{C} end

mutable struct Empty8{C} <: LazyGraph8{C} end

mutable struct Stop8{C} <: LazyGraph8{C}
    c::C
end

mutable struct Build8{C} <: LazyGraph8{C}
    c::C
    _lss
end

function get_lss(g::Build8{C}) where {C}
    if g._lss isa Function
        g._lss = g._lss()
    end
    g._lss
end

# build_graph8

function build_graph8_loop(w, h, c)
    C = conf_type(w)
    if is_foldable_to_history(w, c, h)
        Stop8{C}(c)
    else
        function lss8()
            [[build_graph8_loop(w, cons(c, h), c1) for c1 in cs]
             for cs in develop(w, c)]
        end
        Build8{C}(c, lss8)
    end
end

function build_graph8(w, c0)
    C = conf_type(w)
    build_graph8_loop(w, nil(C), c0)
end

# prune_graph8

function prune_graph8_loop(w, h, l::Empty8)
    C = conf_type(w)
    Empty{C}()
end

function prune_graph8_loop(w, h, l::Stop8)
    C = conf_type(w)
    Stop{C}(l.c)
end

function prune_graph8_loop(w, h, l::Build8)
    C = conf_type(w)
    if is_dangerous(w, h)
        Empty{C}()
    else
        lss = [[prune_graph8_loop(w, cons(l.c, h), l1) for l1 in ls]
               for ls in l.lss]
        Build{C}(l.c, lss)
    end
end

function prune_graph8(w, l0)
    C = conf_type(w)
    prune_graph8_loop(w, nil(C), l0)
end

#
# Now that we have docomposed `lazy_mrsc`
#     lazy_mrsc ≗ prune_graph8 ∘ build_graph8
# we can push some cleaners over `prune_graph8`.
#
# Suppose `clean∞` is a graph8 cleaner such that
#     clean ∘ prune_graph8 ≗ prune_graph8 ∘ clean∞
# then
#     clean ∘ lazy_mrsc ≗
#       clean ∘ (prune_graph8 ∘ build_graph8) ≗
#       (prune_graph8 ∘ clean∞) ∘ build_graph8
#       prune_graph8 ∘ (clean∞ ∘ build_graph8)
#
# The good thing is that `build_graph8` and `clean∞` work in a lazy way,
# generating subtrees by demand. Hence, evaluating
#     unroll( prune-graph8 ∘ (clean∞ (build-graph8 c)) )
# may be less time and space consuming than evaluating
#     unroll( clean (lazy-mrsc c) )
#

# cl8_bad_conf

function cl8_bad_conf(bad, l::Empty8{C})::LazyGraph8{C} where {C}
    l
end

function cl8_bad_conf(bad, l::Stop8{C})::LazyGraph8{C} where {C}
    bad(l.c) ? Empty8{C}() : l
end

function cl8_bad_conf(bad, l::Build8{C})::LazyGraph8{C} where {C}
    if bad(l.c)
        Empty8{C}()
    else
        function lss()
            [[cl8_bad_conf(bad, l1) for l1 in ls] for ls in get_lss(l)]
        end
        Build8{C}(l.c, lss)
    end
end

cl8_bad_conf(bad) = l -> cl8_bad_conf(bad, l)

#
# A graph8 can be cleaned to remove some empty alternatives.
#
# Note that the cleaning is not perfect, because `cl8_empty` has to pass
# the productivity check.
# So, `build(c, [])` is not (recursively) replaced with `Empty8()`. as is done
# by `cl_empty`.
#

# cl8_empty

cl8_empty(l::Empty{C}) where {C} = l
cl8_empty(l::Stop{C}) where {C} = l

function cl8_empty(l::Build8{C})::LazyGraph{C} where {C}
    function lss()
        lss1 = [[cl8_empty(l1) for l1 in ls] for ls in get_lss(l)]
        [ls for ls in lss1 if !(Empty8{C}() in ls)]
    end
    Build8{C}(l.c, lss)
end

# An optimized version of `prune_graph8`.
# The difference is that empty subtrees are removed
# "on the fly".

# prune

function prune_loop(w, h, ::Empty8)
    C = conf_type(w)
    Empty{C}()
end

function prune_loop(w, h, l::Stop8)
    C = conf_type(w)
    Stop{C}(l.c)
end

function prune_loop(w, h, l::Build8)
    C = conf_type(w)
    if is_dangerous(w, h)
        return Empty{C}()
    else
        lss1 = [ls for ls in get_lss(l) if !(Empty8{C}() in ls)]
        lss2 = [[prune_loop(w, cons(l.c, h), l1) for l1 in ls]
                for ls in lss1]
        return Build{C}(l.c, lss2)
    end
end

function prune(w, l0)
    C = conf_type(w)
    prune_loop(w, nil(C), l0)
end

end