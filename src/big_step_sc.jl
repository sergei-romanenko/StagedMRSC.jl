module BigStepSc

export
    History, ScWorld,
    conf_type, is_foldable_to, is_dangerous, develop,
    is_foldable_to_history,
    naive_mrsc, lazy_mrsc

# ### Schemes of different types of big-step supercompilation
#
# A variation of the scheme presented in the paper
#
# Ilya G. Klyuchnikov, Sergei A. Romanenko. Formalizing and Implementing
# Multi-Result Supercompilation.
# In Third International Valentin Turchin Workshop on Metacomputation
# (Proceedings of the Third International Valentin Turchin Workshop on
# Metacomputation. Pereslavl-Zalessky, Russia, July 5-9, 2012).
# A.V. Klimov and S.A. Romanenko, Ed. - Pereslavl-Zalessky: Ailamazyan
# University of Pereslavl, 2012, 260 p. ISBN 978-5-901795-28-6, pages
# 142-164.
#
# Now we formulate an idealized model of big-step multi-result
# supercompilation.
#
# The knowledge about the input language a supercompiler deals with
# is represented by a "world of supercompilation", which is a trait
# that specifies the following.
#
# * `C` is the type of "configurations". Note that configurations are
#   not required to be just expressions with free variables! In general,
#   they may represent sets of states in any form/language and as well may
#   contain any _additional_ information.
#
# * `is_foldable_to` is a "foldability relation". is_foldable_to(w, c, c') means
#   that c is foldable to c'.
#   (In such cases c' is usually said to be " more general than c".)
#
# * `develop` is a function that gives a number of possible decompositions of
#   a configuration. Let `c` be a configuration and `cs` a list of
#   configurations such that `cs ∈ develop(c)`. Then `c` can be "reduced to"
#   (or "decomposed into") configurations in `cs`.
#
#   Suppose that driving is determinstic and, given a configuration `c`,
#   produces a list of configurations `drive(w, c)`. Suppose that rebuilding
#   (generalization, application of lemmas) is non-deterministic and
#   `rebuild(w, c)` is the list of configurations that can be produced by
#   rebuilding. Then (in this special case) `develop` is implemented
#   as follows:
#
#       develop(w, c) = [[drive(w, c)]; rebuild(w, c)]
#
# * `History` is a list of configuration that have been produced
#   in order to reach the current configuration.
#
# * `is_dangerous` is a "whistle" that is used to ensure termination of
#   supercompilation. `is_dangerous(w, h)` means that the history has become
#   "too large".
#
# * `is_foldable_to_history(w, c, h)` means that `c` is foldable to a configuration
#   in the history `h`.

using StagedMRSC.Misc
using StagedMRSC.Graphs
using DataStructures

const History{C} = LinkedList{C}

abstract type ScWorld end

function conf_type(w) end
function is_foldable_to(w, c, c1) end
function is_dangerous(w, h) end
function develop(w, c) end

is_foldable_to_history(w, c, h) =
    any(map(c1 -> is_foldable_to(w, c, c1), h))

# Big-step multi-result supercompilation
# (The naive version builds Cartesian products immediately.)

function naive_mrsc_loop(w, h, c)
    C = conf_type(w)
    if is_foldable_to_history(w, c, h)
        Graph{C}[Back{C}(c)]
    elseif is_dangerous(w, h)
        Graph{C}[]
    else
        css = develop(w, c)
        gsss = [cartesian([naive_mrsc_loop(w, cons(c, h), c1) for c1 in cs])
                for cs in css]
        Graph{C}[Forth{C}(c, gs) for gs in Iterators.flatten(gsss)]
    end
end

function naive_mrsc(w, c0)
    C = conf_type(w)
    naive_mrsc_loop(w, nil(C), c0::C)
end

# "Lazy" multi-result supercompilation.
# (Cartesian products are not immediately built.)
#
# lazy_mrsc is essentially a "staged" version of naive_mrsc
# with `unroll` being an "interpreter" that evaluates the "program"
# returned by lazy_mrsc.

function lazy_mrsc_loop(w, h, c)
    C = conf_type(w)
    if is_foldable_to_history(w, c, h)
        Stop{C}(c)
    elseif is_dangerous(w, h)
        Empty{C}()
    else
        lss = [[lazy_mrsc_loop(w, cons(c, h), c1) for c1 in cs]
               for cs in develop(w, c)]
        Build{C}(c, lss)
    end
end

function lazy_mrsc(w, c0)
    C = conf_type(w)
    lazy_mrsc_loop(w, nil(C), c0::C)
end

end
