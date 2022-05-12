module Protocols

export
    Synapse, MSI, MOSI, ReaderWriter, MESI, MOESI,
    Illinois, Berkley, Firefly, Futurebus, DataRace, Xerox

using StagedMRSC.Counters

import StagedMRSC.Counters: start, rules, is_unsafe

const w = W()

struct Synapse <: CountersWorld end

start(::Synapse) = NW[w, 0, 0]

rules(::Synapse, i::NW, d::NW, v::NW) = [
    (i >= 1, [i + d - 1, 0, v + 1]),
    (v >= 1, [i + d + v - 1, 1, 0]),
    (i >= 1, [i + d + v - 1, 1, 0])]

is_unsafe(::Synapse, i::NW, d::NW, v::NW) =
    (d >= 1 && v >= 1) || (d >= 2)

struct MSI <: CountersWorld end

start(::MSI) = NW[w, 0, 0]

rules(::MSI, i::NW, m::NW, s::NW) = [
    (i >= 1, [i + m + s - 1, 1, 0]),
    (s >= 1, [i + m + s - 1, 1, 0]),
    (i >= 1, [i - 1, 0, m + s + 1])]

is_unsafe(::MSI, i::NW, m::NW, s::NW) =
    (m >= 1 && s >= 1) || (m >= 2)

struct MOSI <: CountersWorld end

start(::MOSI) = NW[w, 0, 0, 0]

rules(::MOSI, i::NW, o::NW, s::NW, m::NW) = [
    (i >= 1, [i - 1, m + o, s + 1, 0]),
    (o >= 1, [i + o + s + m - 1, 0, 0, 1]),
    # wI
    (i >= 1, [i + o + s + m - 1, 0, 0, 1]),
    # wS
    (s >= 1, [i + o + s + m - 1, 0, 0, 1]),
    # se
    (s >= 1, [i + 1, o, s - 1, m]),
    # wbm
    (m >= 1, [i + 1, o, s, m - 1]),
    # wbo
    (o >= 1, [i + 1, o - 1, s, m])]

is_unsafe(::MOSI, i::NW, o::NW, s::NW, m::NW) =
    (o >= 2) || (m >= 2) || (s >= 1 && m >= 1)

struct ReaderWriter <: CountersWorld end

start(::ReaderWriter) = NW[1, 0, 0, w, 0, 0]

rules(::ReaderWriter, x2::NW, x3::NW, x4::NW, x5::NW, x6::NW, x7::NW) = [
    # r1
    (x2 >= 1 && x4 == 0 && x7 >= 1,
        [x2 - 1, x3 + 1, 0, x5, x6, x7]),
    # r2
    (x2 >= 1 && x6 >= 1,
        [x2, x3, x4 + 1, x5, x6 - 1, x7]),
    # r3
    (x3 >= 1,
        [x2 + 1, x3 - 1, x4, x5 + 1, x6, x7]),
    # r4
    (x4 >= 1,
        [x2, x3, x4 - 1, x5 + 1, x6, x7]),
    # r5
    (x5 >= 1,
        [x2, x3, x4, x5 - 1, x6 + 1, x7]),
    # r6
    (x5 >= 1,
        [x2, x3, x4, x5 - 1, x6, x7 + 1])]

is_unsafe(::ReaderWriter, x2::NW, x3::NW, x4::NW, x5::NW, x6::NW, x7::NW) =
    x3 >= 1 && x4 >= 1

struct MESI <: CountersWorld end

start(::MESI) = NW[w, 0, 0, 0]

rules(::MESI, i::NW, e::NW, s::NW, m::NW) = [
    (i >= 1, [i - 1, 0, s + e + m + 1, 0]),
    (e >= 1, [i, e - 1, s, m + 1]),
    (s >= 1, [i + e + s + m - 1, 1, 0, 0]),
    (i >= 1, [i + e + s + m - 1, 1, 0, 0])]

is_unsafe(::MESI, i::NW, e::NW, s::NW, m::NW) =
    m >= 2 || (s >= 1 && m >= 1)

struct MOESI <: CountersWorld end

start(::MOESI) = NW[w, 0, 0, 0, 0]

rules(::MOESI, i::NW, m::NW, s::NW, e::NW, o::NW) = [
    # rm
    (i >= 1, [i - 1, 0, s + e + 1, 0, o + m]),
    # wh2
    (e >= 1, [i, m + 1, s, e - 1, o]),
    # wh3
    (s + o >= 1, [i + m + s + e + o - 1, 0, 0, 1, 0]),
    # wm
    (i >= 1, [i + m + s + e + o - 1, 0, 0, 1, 0])
]

is_unsafe(::MOESI, i::NW, m::NW, s::NW, e::NW, o::NW) =
    (m >= 1 && (e + s + o) >= 1) || (m >= 2) || (e >= 2)

struct Illinois <: CountersWorld end

start(::Illinois) = NW[w, 0, 0, 0]

rules(::Illinois, i::NW, e::NW, d::NW, s::NW) = [
    # r2
    (i >= 1 && e == 0 && d == 0 && s == 0,
        [i - 1, 1, 0, 0]),
    # r3
    (i >= 1 && d >= 1,
        [i - 1, e, d - 1, s + 2]),
    # r4
    (i >= 1 && s + e >= 1,
        [i - 1, 0, d, s + e + 1]),
    # r6
    (e >= 1,
        [i, e - 1, d + 1, s]),
    # r7
    (s >= 1,
        [i + s - 1, e, d + 1, 0]),
    # r8
    (i >= 1,
        [i + e + d + s - 1, 0, 1, 0]),
    # r9
    (d >= 1,
        [i + 1, e, d - 1, s]),
    # r10
    (s >= 1,
        [i + 1, e, d, s - 1]),
    # r11
    (e >= 1,
        [i + 1, e - 1, d, s])]

is_unsafe(::Illinois, i::NW, e::NW, d::NW, s::NW) =
    (d >= 1 && s >= 1) || (d >= 2)

struct Berkley <: CountersWorld end

start(::Berkley) = NW[w, 0, 0, 0]

rules(::Berkley, i::NW, n::NW, u::NW, e::NW) = [
    # rm
    (i >= 1, [i - 1, n + e, u + 1, 0]),
    # wm
    (i >= 1, [i + n + u + e - 1, 0, 0, 1]),
    # wh1
    (n + u >= 1, [i + n + u - 1, 0, 0, e + 1])]

is_unsafe(::Berkley, i::NW, n::NW, u::NW, e::NW) =
    (e >= 1 && u + n >= 1) || (e >= 2)

struct Firefly <: CountersWorld end

start(::Firefly) = NW[w, 0, 0, 0]

rules(::Firefly, i::NW, e::NW, s::NW, d::NW) = [
    # rm1
    (i >= 1 && d == 0 && s == 0 && e == 0,
        [i - 1, 1, 0, 0]),
    # rm2
    (i >= 1 && d >= 1,
        [i - 1, e, s + 2, d - 1]),
    # rm3
    (i >= 1 && s + e >= 1,
        [i - 1, 0, s + e + 1, d]),
    # wh2
    (e >= 1,
        [i, e - 1, s, d + 1]),
    # wh3
    (s == 1,
        [i, e + 1, 0, d]),
    # wm
    (i >= 1,
        [i + e + d + s - 1, 0, 0, 1])]

is_unsafe(::Firefly, i::NW, e::NW, s::NW, d::NW) =
    (d >= 1 && s + e >= 1) || (e >= 2) || (d >= 2)

struct Futurebus <: CountersWorld end

start(::Futurebus) = NW[w, 0, 0, 0, 0, 0, 0, 0, 0]

rules(::Futurebus, i::NW, sU::NW, eU::NW, eM::NW, pR::NW,
    pW::NW, pEMR::NW, pEMW::NW, pSU::NW) = [
    # r2
    (i >= 1 && pW == 0,
        [i - 1, 0, 0, 0, pR + 1, pW, pEMR + eM, pEMW, pSU + sU + eU]),
    # r3
    (pEMR >= 1,
        [i, sU + pR + 1, eU, eM, 0, pW, pEMR - 1, pEMW, pSU]),
    # r4
    (pSU >= 1,
        [i, sU + pR + pSU, eU, eM, 0, pW, pEMR, pEMW, 0]),
    # r5
    (pR >= 2 && pSU == 0 && pEMR == 0,
        [i, sU + pR, eU, eM, 0, pW, 0, pEMW, 0]),
    # r6
    (pR == 1 && pSU == 0 && pEMR == 0,
        [i, sU, eU + 1, eM, 0, pW, 0, pEMW, 0]),
    # wm1
    (i >= 1 && pW == 0,
        [i + eU + sU + pSU + pR + pEMR - 1, 0, 0, 0, 0, 1, 0, pEMW + eM, 0]),
    # wm2
    (pEMW >= 1,
        [i + 1, sU, eU, eM + pW, pR, 0, pEMR, pEMW - 1, pSU]),
    # wm3
    (pEMW == 0,
        [i, sU, eU, eM + pW, pR, 0, pEMR, 0, pSU]),
    # wh2
    (eU >= 1,
        [i, sU, eU - 1, eM + 1, pR, pW, pEMR, pEMW, pSU]),
    # wh2
    (sU >= 1,
        [i + sU - 1, 0, eU, eM + 1, pR, pW, pEMR, pEMW, pSU])]

is_unsafe(::Futurebus, i::NW, sU::NW, eU::NW, eM::NW, pR::NW,
    pW::NW, pEMR::NW, pEMW::NW, pSU::NW) =
    (sU >= 1 && eU + eM >= 1) ||
    (eU + eM >= 2) ||
    (pR >= 1 && pW >= 1) ||
    (pW >= 2)

struct DataRace <: CountersWorld end

start(::DataRace) = NW[w, 0, 0]

rules(::DataRace, out::NW, cs::NW, scs::NW) = [
    # 1
    (out >= 1 && cs == 0 && scs == 0,
        [out - 1, 1, 0]),
    # 2
    (out >= 1 && cs == 0,
        [out - 1, 0, scs + 1]),
    # 3
    (cs >= 1,
        [out + 1, cs - 1, scs]),
    # 4
    (scs >= 1,
        [out + 1, cs, scs - 1])]

is_unsafe(::DataRace, out::NW, cs::NW, scs::NW) =
    cs >= 1 && scs >= 1

struct Xerox <: CountersWorld end

start(::Xerox) = NW[w, 0, 0, 0, 0]

rules(::Xerox, i::NW, sc::NW, sd::NW, d::NW, e::NW) = [
    # (1) rm1
    (i >= 1 && d == 0 && sc == 0 && sd == 0 && e == 0,
        [i - 1, 0, 0, 0, 1]),
    # (2) rm2
    (i >= 1 && d + sc + e + sd >= 1,
        [i - 1, sc + e + 1, sd + d, 0, 0]),
    # (3) wm1
    (i >= 1 && d == 0 && sc == 0 && sd == 0 && e == 0,
        [i - 1, 0, 0, 1, 0]),
    # (4) wm2
    (i >= 1 && d + sc + e + sd >= 1,
        [i - 1, sc + e + 1 + (sd + d), sd, 0, 0]),
    # (5) wh1
    (d >= 1,
        [i + 1, sc, sd, d - 1, e]),
    # (6) wh2
    (sc >= 1,
        [i + 1, sc - 1, sd, d, e]),
    # (7) wh3
    (sd >= 1,
        [i + 1, sc, sd - 1, d, e]),
    # (8) wh4
    (e >= 1,
        [i + 1, sc, sd, d, e - 1])
]

is_unsafe(::Xerox, i::NW, sc::NW, sd::NW, d::NW, e::NW) =
    return (d >= 1 && (e + sc + sd) >= 1) ||
           (e >= 1 && (sc + sd) >= 1) ||
           (d >= 2) ||
           (e >= 2)

end