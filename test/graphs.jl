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

@info "Testing CartProd"

@testset "Graphs - show" begin
  @test "Back(1)" == string(g_back)
  @test "Forth(1, [Back(1)])" == string(g_forth)
  @test "Forth(1, [Back(1), Forth(2, [Back(1), Back(2)])])" == string(g1)
end

function test_unroll(l, g)
  @test string(unroll(l)) == string(g)
end

@testset "Graphs - unroll" begin
  test_unroll(IEmpty(), [])
  test_unroll(IStop(100), [IBack(100)])
  test_unroll(IStop(100), [IBack(100)])
  test_unroll(l2, gs2)
end

@testset "Graphs - bad_graph" begin
  @test !bad_graph(ibad, g1)
  @test bad_graph(ibad, g_bad_forth)
  @test bad_graph(ibad, g_bad_back)
end

end
