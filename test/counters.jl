module Counters_Test

using Test
using StagedMRSC.Graphs
using StagedMRSC.BigStepSc
using StagedMRSC.Counters

import StagedMRSC.Counters: conf_length, start, max_N, max_depth, rules

struct TestWorld <: CountersScWorld end

conf_length(::TestWorld) = 2

start(::TestWorld) = NW[2, 0]

rules(::TestWorld, i::NW, j::NW) = [
    (i >=′ 1, [i -′ 1, j +′ 1]),
    (j >=′ 1, [i +′ 1, j -′ 1])]

is_unsafe(::TestWorld, c) = false

max_N(::TestWorld) = 3
max_depth(::TestWorld) = 10

const C = conf_type(TestWorld())
const CGraph = Graph{C}
const CBack = Back{C}
const CForth = Forth{C}

const mg =
    CForth([2, 0], [
        CForth([W(), W()], [
            CBack([W(), W()]),
            CBack([W(), W()])])])

@testset "Counters_Test" begin
    w = TestWorld()
    start_conf = start(w)
    gs = naive_mrsc(w, start_conf)
    # println("gs.length == $(length(gs))")
    l = lazy_mrsc(w, start_conf)
    @test unroll(l) == gs
    ml = cl_min_size(l)
    @test unroll(ml)[1] == mg
end

end
