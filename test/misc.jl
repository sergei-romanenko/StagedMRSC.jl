module Misc_Test

using Test
using StagedMRSC.Misc

@info "Testing CartProd"

@testset "CartProd" begin

  @test length(CartProd{Int64}([])) == 0
  @test length(CartProd([[1, 1, 1]])) == 3
  @test length(CartProd([[1], [], [2]])) == 0
  @test length(CartProd([[1, 1, 1], [2, 2, 2, 2, 2]])) == 15

  @test cartesian(Vector{Int64}[]) == []

  @test cartesian([[1, 2]]) == [[1], [2]]

  @test cartesian([[1, 2], [], [100, 200]]) == []

  @test cartesian([[1, 2], [10, 20, 30], [100, 200]]) ==
        [[1, 10, 100], [1, 10, 200],
    [1, 20, 100], [1, 20, 200],
    [1, 30, 100], [1, 30, 200],
    [2, 10, 100], [2, 10, 200],
    [2, 20, 100], [2, 20, 200],
    [2, 30, 100], [2, 30, 200]]

end

end
