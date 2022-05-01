module Graphs_Test

using Test
using StagedMRSC.Graphs

const IGraph = Graph{Int64}
const IBack = Back{Int64}
const IForth = Forth{Int64}

const ILazyGraph = LazyGraph{Int64}
const IEmpty = Empty{Int64}
const IStop = Stop{Int64}
const IBuild = Build{Int64}

ibad(c::Int64)::Bool = c < 0

g_back = IBack(1)

g_forth = IForth(1, [IBack(1)])

g1 =
  IForth(1, [
    IBack(1),
    IForth(2, [
      IBack(1),
      IBack(2)])])

g_bad_forth =
  IForth(1, [
    IBack(1),
    IForth(-2, [
      IBack(3),
      IBack(4)])])

g_bad_back =
  IForth(1, [
    IBack(1),
    IForth(2, [
      IBack(3),
      IBack(-4)])])

l2 =
  IBuild(1, [
    [IBuild(2, [[IStop(1), IStop(2)]])],
    [IBuild(3, [[IStop(3), IStop(1)]])]])

gs2 = [IForth(1, [IForth(2, [IBack(1), IBack(2)])]),
  IForth(1, [IForth(3, [IBack(3), IBack(1)])])]

l_empty =
  IBuild(1, [
    [IStop(2)],
    [IBuild(3, [
      [IStop(4), IEmpty()]])]])

l_bad_build =
  IBuild(1, [
    [IStop(1),
    IBuild(-2, [[
      IStop(3), IStop(4)]])]])

l_bad_stop =
  IBuild(1, [
    [IStop(1),
    IBuild(2, [[
      IStop(3),
      IStop(-4)]])]])

l3 =
  IBuild(1, [
    [IBuild(2, [
      [IStop(1), IStop(2)]])],
    [IBuild(3, [
      [IStop(4)]])]])

@testset "Graphs - show" begin
  @test "Back(1)" == string(g_back)
  @test "Forth(1, [Back(1)])" == string(g_forth)
  @test "Forth(1, [Back(1), Forth(2, [Back(1), Back(2)])])" == string(g1)
end

@testset "Graphs - Graph ==" begin
  @test IBack(1) == IBack(1)
  @test IBack(1) != IBack(2)
  @test IForth(1, [IBack(1)]) == IForth(1, [IBack(1)])
  @test IForth(1, [IBack(1)]) != IForth(2, [IBack(1)])
  @test IForth(1, [IBack(1)]) != IForth(1, [IBack(2)])
end

@testset "Graphs - LazyGraph ==" begin
  @test IEmpty() == IEmpty()
  @test IStop(1) == IStop(1)
  @test IStop(1) != IStop(2)
  @test IBuild(1, [[IStop(1)]]) == IBuild(1, [[IStop(1)]])
  @test IBuild(1, [[IStop(1)]]) != IBuild(2, [[IStop(1)]])
  @test IBuild(1, [[IStop(1)]]) != IBuild(1, [[IStop(2)]])
end

@testset "Graphs - unroll" begin
  @test unroll(IEmpty()) == []
  @test unroll(IStop(100)) == [IBack(100)]
  @test unroll(l2) == gs2
end

@testset "Graphs - bad_graph" begin
  @test !bad_graph(ibad, g1)
  @test bad_graph(ibad, g_bad_forth)
  @test bad_graph(ibad, g_bad_back)
end

@testset "Graphs - cl_empty" begin
  @test cl_empty(l_empty) == IBuild(1, [[IStop(2)]])
end

@testset "Graphs - cl_bad_conf" begin
  @test cl_bad_conf(ibad, l_bad_build) ==
        IBuild(1, [[IStop(1), IEmpty()]])
  @test cl_bad_conf(ibad, l_bad_stop) ==
        IBuild(1, [ILazyGraph[IStop(1), IBuild(2, [ILazyGraph[IStop(3), IEmpty()]])]])

end

@testset "Graphs - cl_empty_and_bad" begin
  @test cl_empty_and_bad(ibad, l_bad_build) == IEmpty()
  @test cl_empty_and_bad(ibad, l_bad_stop) == IEmpty()
end

@testset "Graphs - graph_size" begin
  @test graph_size(g1) == 5
end

@testset "Graphs - cl_min_size" begin
  @test cl_min_size(l3) == IBuild(1, [[IBuild(3, [[IStop(4)]])]])
end

@testset "Graphs cl_min_size, unroll" begin
  min_l = cl_min_size(l3)
  min_g = unroll(min_l)[1]
  @test min_g == IForth(1, [IForth(3, [IBack(4)])])
end

end
