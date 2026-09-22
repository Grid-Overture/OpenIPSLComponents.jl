# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# PortTests/ThreePhase/Dyn_wye_1Ph.mo (a Test of this port, not OpenIPSL's: PLAN-12), transcribed automatically (2026-09-21); reviewed by hand.
# extends: none. Omitted: graphical annotations, displayPF.
@component function Dyn_wye_1Ph_Test(; name, S_b = 100e6, fn = 60)
    systems = @named begin
        InfiniteBus = ThreePhase_InfiniteBus(; S_b, fn)
        Bus1 = Bus_3Ph(; S_b, fn)
        L684_611 = Line_1Ph(; Gser = 1.1301, Bser = -1.1456, S_b, fn)
        Bus611 = Bus_1Ph(; angle_1 = 2.0943951023931953, S_b, fn)
        Load = Dyn_wye_1Ph(; P0 = 170e3, Q0 = 80e3, S_b, fn)
        rampP = Ramp(; offset = 0.0051, height = 0.00255, startTime = 1, duration = 2)
        constQ = Constant(; k = 0.0024)
    end
    eqs = Equation[
        connect(InfiniteBus.p1, Bus1.p1),
        connect(InfiniteBus.p2, Bus1.p2),
        connect(InfiniteBus.p3, Bus1.p3),
        connect(Bus1.p3, L684_611.Ain),
        connect(L684_611.Aout, Bus611.p1),
        connect(Bus611.p1, Load.A),
        rampP.y ~ Load.P_in,   # connect(rampP.y, Load.P_in)
        constQ.y ~ Load.Q_in,   # connect(constQ.y, Load.Q_in)
    ]
    System(eqs, t, [], []; name, systems)
end
# Batch 13, PLAN-13 step 2.1. Network R1 of the plan: the three-phase source with its own defaults, a
# three-phase bus, and the single-phase lateral of `IEEE13`'s `L684_611` on phase c with 170 kW/80 kvar
# (`SpotLoad611`, read in kW). Zero states; the two time events of the `Ramp` on `P_in` are the only thing that
# happens (F-95 a). Phases a and b of `Bus1` carry no current, which the oracle checks as an identity.
@testset "PortTests.ThreePhase.Dyn_wye_1Ph" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "oracle", "ThreePhase.Dyn_wye_1Ph.jl"))
    validate_against_oracle(Dyn_wye_1Ph_Test, oracle)
end
