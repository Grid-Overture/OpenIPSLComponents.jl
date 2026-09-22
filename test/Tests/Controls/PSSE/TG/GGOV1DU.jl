# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Controls/PSSE/TG/GGOV1DU.mo, transcribed by hand (2026-09-15).
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# The twin of the GGOV1 Test with the same machine and the same data except `Teng = 0`: the `FixedDelay` degenerates
# to `y = u` (F-49) and the model is a plain ODE, which is why this one needs no Padé fallback.
@component function GGOV1DU_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1 = base
    systems = @named begin
        gENROU = GENROU(; Xppd = 0.2, Xppq = 0.2, Xpp = 0.2, Xl = 0.12, Tpd0 = 5.0, Tppd0 = 0.05, Tppq0 = 0.1, H = 4.0, D = 0.0, Xd = 1.41, Xq = 1.35, Xpd = 0.3, S10 = 0.1, S12 = 0.5, Xpq = 0.6, Tpq0 = 0.7, angle_0 = 0.07068583470577, M_b = 100000000.0, P_0 = 39999950.0, Q_0 = 5416571.0, v_0 = 1.0, S_b, fn)
        gGOV1DU = GGOV1DU(; R = 0.0, T_pelec = 1.0, maxerr = 0.05, minerr = -0.05, Kpgov = 10.0, Kigov = 2.0, Kdgov = 0.0, Tdgov = 1.0, Vmax = 1.0, Vmin = 0.15, Tact = 0.5, Kturb = 1.5, Wfnl = 0.2, Tb = 0.1, Tc = 0.0, Teng = 0.0, Tfload = 3.0, Kpload = 2.0, Kiload = 0.67, Ldref = 1.0, Dm = 0.0, Ropen = 0.1, Rclose = -0.1, Kimw = 0.0, Aset = 0.1, Ka = 10.0, Ta = 0.1, Trate = 0.0, db = 0.0, Tsa = 4.0, Tsb = 5.0, Rup = 99.0, Rdown = -99.0, DELT = 0.0001, Flag = 0, Rselect = 0)
    end
    eqs = Equation[
        gGOV1DU.PELEC ~ gENROU.PELEC,   # connect(gGOV1DU.PELEC, gENROU.PELEC)
        gENROU.EFD0 ~ gENROU.EFD,       # connect(gENROU.EFD0, gENROU.EFD)
        gGOV1DU.PMECH ~ gENROU.PMECH,   # connect(gGOV1DU.PMECH, gENROU.PMECH)
        gENROU.SPEED ~ gGOV1DU.SPEED,   # connect(gENROU.SPEED, gGOV1DU.SPEED)
        connect(gENROU.p, GEN1.p),
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Controls.PSSE.TG.GGOV1DU" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSSE.TG.GGOV1DU.jl"))
    validate_against_oracle(GGOV1DU_Test, oracle)
end
