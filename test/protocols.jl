module Protocols_Test

using Test
using StagedMRSC.BigStepSc
using StagedMRSC.Counters
using StagedMRSC.Graphs
using StagedMRSC.Protocols
using StagedMRSC.Statistics

function run_min_sc(cw::CountersWorld, m::Int, d::Int)
    name = last(split(string(typeof(cw)), "."))
    print("\n$name ")
    w = CountersScWorld{typeof(cw),m,d}()
    l = lazy_mrsc(w, start(w))
    sl = cl_empty_and_bad(is_unsafe(cw), l)
    len_usl, size_usl = size_unroll(sl)
    println("($len_usl, $size_usl)")
    ml = cl_min_size(sl)
    gs = unroll(ml)
    if isempty(gs)
        println(": No solution")
    else
        mg = gs[1]
        println(graph_pretty_printer(mg, nw_conf_pp))
    end
end

@testset "Protocols" begin
    run_min_sc(Synapse(), 3, 10)
    run_min_sc(MSI(), 3, 10)
    run_min_sc(MOSI(), 3, 10)
    run_min_sc(ReaderWriter(), 3, 5)
    run_min_sc(MESI(), 3, 10)
    run_min_sc(MOESI(), 3, 5)
    run_min_sc(Illinois(), 3, 5)
    run_min_sc(Berkley(), 3, 5)
    run_min_sc(Firefly(), 3, 5)
    run_min_sc(DataRace(), 3, 10)
    # Slow!
    # run_min_sc(Futurebus(), 3, 5)
    # run_min_sc(Xerox(), 3, 5)
end

end
