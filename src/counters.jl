module Counters

export
  W, NW,
  nw_conf_pp,
  start, rules, is_unsafe,
  CountersWorld, CountersScWorld

using StagedMRSC.Misc
using StagedMRSC.BigStepSc

import StagedMRSC.BigStepSc: conf_type, is_dangerous, is_foldable_to, develop

abstract type NW end

# All Ns
struct W <: NW end

struct N <: NW
  n::Int
end

function Base.show(io::IO, i::W)
  print(io, "ω")
end

function Base.show(io::IO, i::N)
  print(io, i.n)
  # print(io, "′")
end

Base.convert(::Type{NW}, i::Int) = N(i)

Base.:(+)(i::N, j::N) = N(i.n + j.n)
Base.:(+)(i::N, j::Int) = N(i.n + j)
Base.:(+)(::N, ::W) = W()
Base.:(+)(::W, j) = W()

Base.:(-)(i::N, j::N) = N(i.n - j.n)
Base.:(-)(i::N, j::Int) = N(i.n - j)
Base.:(-)(::N, ::W) = W()
Base.:(-)(::W, j) = W()

Base.:(>=)(i::N, j::Int) = i.n >= j
Base.:(>=)(::W, ::Int) = true

Base.:(==)(i::N, j::Int) = i.n == j
Base.:(==)(::W, ::Int) = true

is_in(i::N, j::N) = i.n == j.n
is_in(::NW, ::W) = true
is_in(::W, ::N) = false

nw_conf_pp(c::Vector{NW}) =
  string("(", join(map(string, c), ", "), ")")

# CountersScWorld

abstract type CountersWorld end

function start end
function rules end
function is_unsafe end

is_unsafe(w::CountersWorld, c::Vector{NW}) =
  is_unsafe(w, c...)

is_unsafe(w::CountersWorld) =
  c -> is_unsafe(w, c)

struct CountersScWorld{CW,MAX_NW,MAX_DEPTH} <: ScWorld end

conf_type(::CountersScWorld) = Vector{NW}

start(::CountersScWorld{CW,MAX_NW,MAX_DEPTH}) where {CW,MAX_NW,MAX_DEPTH} =
  start(CW())

rules(::CountersScWorld{CW,MAX_NW,MAX_DEPTH}, c...) where {CW,MAX_NW,MAX_DEPTH} =
  rules(CW(), c...)

function max_depth(::CountersScWorld{CW,MAX_NW,MAX_DEPTH}) where {CW,MAX_NW,MAX_DEPTH}
  MAX_DEPTH
end

function max_nw(::CountersScWorld{CW,MAX_NW,MAX_DEPTH}) where {CW,MAX_NW,MAX_DEPTH}
  MAX_NW
end

is_too_big_nw(w, nw::W) = false
is_too_big_nw(w, i::N) = i.n >= max_nw(w)

is_too_big(w) =
  c -> any(i -> is_too_big_nw(w, i), c)

function is_dangerous(w, h)
  any(is_too_big(w), h) || length(h) >= max_depth(w)
end

is_foldable_to(w, c1, c2) =
  all(is_in(nw1, nw2) for (nw1, nw2) in Iterators.zip(c1, c2))

# Driving is deterministic

function drive(w, c)
  C = conf_type(w)
  [C[r for (p, r) in rules(w, c...) if p]]
end

# Rebuilding is not deterministic,
# but makes a single configuration from a configuration.

rebuild1(::W) = NW[W()]
rebuild1(i::N) = NW[i, W()]

function rebuild(w, c)
  C = conf_type(w)
  rb = [rebuild1(nw) for nw in c]
  cs = cartesian([rebuild1(nw) for nw in c])
  [C[c1] for c1 in cs if !(c1 == c)]
end

function develop(w, c)
  [drive(w, c); rebuild(w, c)]
end

end
