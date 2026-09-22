# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Controls/PSSE/TG/GGOV1.mo, transcribed by hand (2026-09-15).
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# GENROU with no exciter (EFD0 <- EFD). The Test runs the governor isochronous (R = 0, Rselect = 0), with
# `Flag = 0`, `DELT = 1e-4` and, above all, `Teng = 0.5`: a real 0.5 s transport lag inside the turbine, the only
# Test of OpenIPSL 3.1.0 that exercises `Modelica.Blocks.Nonlinear.FixedDelay` with a non-zero delay.
#
# `pade`: ModelingToolkit 11.43 cannot evaluate the condition of an event inside a delayed system (F-51) and the
# SMIB base has `PwFault`'s two time events, so the Test cannot be integrated as a `DDEProblem`. The delay is
# therefore the Padé approximation of the same `Teng` (plan B of F-20 d), a Julia-only deviation whose error against
# the transport-delay oracle is the measurement of PLAN-05's "Retardos" decision.
@component function GGOV1_Test(; name, S_b = 100e6, fn = 50, pade = 0)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1 = base
    systems = @named begin
        gENROU = GENROU(; Xppd = 0.2, Xppq = 0.2, Xpp = 0.2, Xl = 0.12, Tpd0 = 5.0, Tppd0 = 0.05, Tppq0 = 0.1, H = 4.0, D = 0.0, Xd = 1.41, Xq = 1.35, Xpd = 0.3, S10 = 0.1, S12 = 0.5, Xpq = 0.6, Tpq0 = 0.7, angle_0 = 0.07068583470577, M_b = 100000000.0, P_0 = 39999950.0, Q_0 = 5416571.0, v_0 = 1.0, S_b, fn)
        gGOV1 = GGOV1(; R = 0.0, T_pelec = 1.0, maxerr = 0.05, minerr = -0.05, Kpgov = 10.0, Kigov = 2.0, Kdgov = 0.0, Tdgov = 1.0, Vmax = 1.0, Vmin = 0.15, Tact = 0.5, Kturb = 1.5, Wfnl = 0.2, Tb = 0.1, Tc = 0.0, Teng = 0.5, Tfload = 3.0, Kpload = 2.0, Kiload = 0.67, Ldref = 1.0, Dm = 0.0, Ropen = 0.1, Rclose = -0.1, Kimw = 0.0, Aset = 0.1, Ka = 10.0, Ta = 0.1, Trate = 0.0, db = 0.0, Tsa = 4.0, Tsb = 5.0, Rup = 99.0, Rdown = -99.0, DELT = 0.0001, Flag = 0, Rselect = 0, pade)
    end
    eqs = Equation[
        gGOV1.PELEC ~ gENROU.PELEC,   # connect(gGOV1.PELEC, gENROU.PELEC)
        gENROU.EFD0 ~ gENROU.EFD,     # connect(gENROU.EFD0, gENROU.EFD)
        gGOV1.PMECH ~ gENROU.PMECH,   # connect(gGOV1.PMECH, gENROU.PMECH)
        gENROU.SPEED ~ gGOV1.SPEED,   # connect(gENROU.SPEED, gGOV1.SPEED)
        connect(gENROU.p, GEN1.p),
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

# Measured against the transport-delay oracle (F-51): the delay is real (OpenModelica's `fixedDelay.y` equals its
# input shifted by exactly 0.5 s, and the two differ by up to 0.04 pu, 80 times the acceptance limit, so dropping it
# is not an option). Worst ratio to the per-variable limit by Padé order: n = 2 (the order `Turbine.mo` writes for
# its own, unused, `padeDelay`) 16.4, n = 4 2.37, n = 6 1.39, **n = 8 0.213**. The Test therefore runs with n = 8 and
# the default threshold; the worst variable is `gGOV1_Turb.fixedDelay.y` itself at 1.07e-4 (limit 5.0e-4).
@testset "Tests.Controls.PSSE.TG.GGOV1" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSSE.TG.GGOV1.jl"))
    validate_against_oracle(GGOV1_Test, oracle; pade = 8)
end
