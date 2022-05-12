module Protocols_Test

#= 
from smrsc.big_step_sc import lazy_mrsc
from smrsc.counters import \
    CountersWorld, CountersScWorld, nw_conf_pp, norm_nw_conf
from smrsc.graph import \
    graph_pretty_printer, cl_empty_and_bad, cl_min_size, unroll
from smrsc.protocols import *
from smrsc.statistics import size_unroll
 =#

using Test
using StagedMRSC.BigStepSc
using StagedMRSC.Counters
using StagedMRSC.Graphs
using StagedMRSC.Protocols
using StagedMRSC.Statistics

#=  
class TestProtocols(unittest.TestCase):
    def run_min_sc(self, cnt: CountersWorld, m: int, d: int):
        name = type(cnt).__name__
        print("\n%s " % name, end="")
        w = CountersScWorld(cnt, m, d)
        l = lazy_mrsc(w, w.start)
        sl = cl_empty_and_bad(w.is_unsafe)(l)
        len_usl, size_usl = size_unroll(sl)
        print("(%s, %s)" % (len_usl, size_usl))
        ml = cl_min_size(sl)
        mg = unroll(ml)[0]
        print(graph_pretty_printer(mg, cstr=nw_conf_pp))
=#

function run_min_sc(cw::CountersWorld, m::Int, d::Int)
    name = last(split(string(typeof(cw)), "."))
    print("\n$name ")
    w = CountersScWorld{typeof(cw),m,d}()
    l = lazy_mrsc(w, start(w))
    # @show l
    sl = cl_empty_and_bad(is_unsafe(cw), l)
    # @show sl
    len_usl, size_usl = size_unroll(sl)
    println("($len_usl, $size_usl)")
    ml = cl_min_size(sl)
    # @show ml
    # @show unroll(ml)
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