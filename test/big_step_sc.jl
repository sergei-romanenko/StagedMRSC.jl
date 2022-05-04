module BigStepSC_Test

using Test
using StagedMRSC.Graphs
using StagedMRSC.BigStepSC

include("mock_sc_worlds.jl")

const IGraph = Graph{Int}
const IBack = Back{Int}
const IForth = Forth{Int}

gs3 =
    [IForth(0, [IForth(1, [IForth(2, [IBack(0), IBack(1)])])]),
        IForth(0, [IForth(1, [IForth(2, [IBack(1)])])]),
        IForth(0, [IForth(1, [IForth(2, [IForth(3, [IBack(0), IBack(2)])])])]),
        IForth(0, [IForth(1, [IForth(2, [IForth(3, [IBack(2)])])])])]

function naive_mrsc_int(c::Int)
    naive_mrsc(IntScWorld(), c)
end

function lazy_mrsc_int(c::Int)
    lazy_mrsc(IntScWorld(), c)
end

@testset "BigStepSC - naive_mrsc" begin
    @test naive_mrsc_int(0) == gs3
end

@testset "BigStepSC - lazy_mrsc" begin
    @test unroll(lazy_mrsc_int(0)) == gs3
    @test unroll(cl_min_size(lazy_mrsc_int(0))) ==
          [IForth(0, [IForth(1, [IForth(2, [IBack(1)])])])]
end

end
