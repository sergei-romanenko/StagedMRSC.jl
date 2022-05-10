module Counters

export
  W, NW,
  rule_type, start, rules, is_unsafe,
  CountersScWorld,
  +′, -′, >=′, ==′, in′

using StagedMRSC.Misc
using StagedMRSC.BigStepSC

import StagedMRSC.BigStepSC: conf_type, is_dangerous, is_foldable_to, develop

abstract type NW end

# Infinity
struct W <: NW end

struct N <: NW
  n::Int
end

function Base.show(io::IO, i::W)
  print(io, "ω")
end

function Base.show(io::IO, i::N)
  print(io, i.n)
  print(io, "′")
end

Base.convert(::Type{NW}, i::Int) = N(i)

+′(i::N, j::N) = N(i.n + j.n)
+′(::Int, ::W) = W()
+′(::W, ::NW) = W()
+′(i::NW, j::Int) = i +′ N(j)

-′(i::N, j::N) = N(i.n - j.n)
-′(::N, ::W) = W()
-′(::W, ::NW) = W()
-′(i::NW, j::Int) = i -′ N(j)

>=′(i::N, j::N) = i.n >= j.n
>=′(::W, ::N) = true
>=′(i::NW, j::Int) = i >=′ N(j)

==′(i::N, j::N) = i.n == j.n
==′(::W, ::N) = true

in′(i::N, j::N) = i.n == j.n
in′(::NW, ::W) = true
in′(::W, ::N) = false

abstract type CountersScWorld <: ScWorld end

function conf_length(::CountersScWorld)::Int end

conf_type(::CountersScWorld) = Vector{NW}

function start(::CountersScWorld) end
# function rules(::CountersScWorld) end
function rules end

# function is_unsafe(::CountersScWorld) end
function is_unsafe end

function max_N(::CountersScWorld)::Int end
function max_depth(::CountersScWorld)::Int end

is_too_big_nw(::CountersScWorld, nw::W) =
  false

is_too_big_nw(w::CountersScWorld, i::N) =
  i.n >= max_N(w)

is_too_big_nw(w) = i -> is_too_big_nw(w, i)

is_too_big(w::CountersScWorld) =
  c -> any(is_too_big_nw(w), c)

is_dangerous(w::CountersScWorld, h) =
  any(is_too_big(w), h) || length(h) >= max_depth(w)

is_foldable_to(::CountersScWorld, c1, c2) =
  all(in′(nw1, nw2) for (nw1, nw2) in Iterators.zip(c1, c2))

# Driving is deterministic

function drive(w::CountersScWorld, c)
  C = conf_type(w)
  [C[r for (p, r) in rules(w, c...) if p]]
end

# Rebuilding is not deterministic,
# but makes a single configuration from a configuration.

rebuild1(::W) = NW[W()]
rebuild1(i::N) = NW[i, W()]

function rebuild(w::CountersScWorld, c)
  C = conf_type(w)
  rb = [rebuild1(nw) for nw in c]
  cs = cartesian([rebuild1(nw) for nw in c])
  [C[c1] for c1 in cs if !(c1 == c)]
end

function develop(w::CountersScWorld, c)
  [drive(w, c); rebuild(w, c)]
end

end
