module Statistics_Test

using Test
using StagedMRSC.Graphs
using StagedMRSC.BigStepSc
using StagedMRSC.Statistics

include("mock_sc_worlds.jl")

function naive_mrsc_int(c::Int)
    naive_mrsc(IntScWorld(), c)
end

function lazy_mrsc_int(c::Int)
    lazy_mrsc(IntScWorld(), c)
end

@testset "Statistics - length_unroll" begin
    l1 = lazy_mrsc_int(0)
    ul1 = unroll(l1)

    @test length_unroll(l1) == length(ul1)
    @test size_unroll(l1) == (length(ul1), sum(map(graph_size, ul1)))
end

end
