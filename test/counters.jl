module Counters_Test

using Test
using StagedMRSC.Graphs
using StagedMRSC.BigStepSc
using StagedMRSC.Counters

import StagedMRSC.Counters: start, rules

struct TestCW <: CountersWorld end

start(::TestCW) = NW[2, 0]

rules(::TestCW, i::NW, j::NW) = [
    (i >=′ 1, [i -′ 1, j +′ 1]),
    (j >=′ 1, [i +′ 1, j -′ 1])]

is_unsafe(::TestCW, c) = false

struct TestScW{MAX_NW,MAX_DEPTH} <:
       CountersScWorld{TestCW,MAX_NW,MAX_DEPTH} end

const C = conf_type(TestScW{3,10}())
const CGraph = Graph{C}
const CBack = Back{C}
const CForth = Forth{C}

const mg =
    CForth([2, 0], [
        CForth([W(), W()], [
            CBack([W(), W()]),
            CBack([W(), W()])])])

@testset "Counters_Test" begin
    w = TestScW{3,10}()
    start_conf = start(w)
    gs = naive_mrsc(w, start_conf)
    # println("gs.length == $(length(gs))")
    l = lazy_mrsc(w, start_conf)
    @test unroll(l) == gs
    ml = cl_min_size(l)
    @test unroll(ml)[1] == mg
end

end
