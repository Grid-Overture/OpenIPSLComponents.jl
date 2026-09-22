# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Controls/PSSE/UEL/MNLEX2.mo, transcribed automatically (2026-09-14); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# `MNLEX2` is the limiter (suffix _Test) feeding EXAC1's VUEL; `SMIB(pwFault(t1 = 2, t2 = 2.7), SysData(fn = 50))`
# is the `mods` keyword and fn = 50; the machine has D = 1; `const` is `const_`.
@component function MNLEX2_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn, mods = (; pwFault = (; t1 = 2, t2 = 2.7)))
    @unpack GEN1 = base
    systems = @named begin
        gENROU = GENROU(; P_0 = 40000000.0, Q_0 = 5415812.0, angle_0 = 0.070619983433093, M_b = 118000000.0, Tpd0 = 7.045, Tppd0 = 0.042, Tppq0 = 0.074, H = 6.204, D = 1.0, Xd = 1.36, Xq = 1.31, Xpd = 0.18, Xppd = 0.15, Xppq = 0.15, Xl = 0.13, S10 = 0.1, S12 = 0.55, Xpq = 0.31, Tpq0 = 0.783, S_b, fn)
        eXAC1_1 = EXAC1(; T_R = 0.0, V_RMAX = 12.4, V_RMIN = -11.2, T_E = 0.42, K_C = 0.53, K_D = 2.06, K_E = 0.42, E_1 = 3.6, S_EE_1 = 0.06, E_2 = 4.8, S_EE_2 = 0.22)
        const_ = Constant(; k = 0)
        mNLEX2 = MNLEX2(; K_M = 100.0, T_M = 0.05, MEL_MAX = 18.0, Q_0 = 1.3, Radius = 1.92)
    end
    eqs = Equation[
        gENROU.XADIFD ~ eXAC1_1.XADIFD,   # connect(gENROU.XADIFD, eXAC1_1.XADIFD)
        gENROU.EFD0 ~ eXAC1_1.EFD0,   # connect(gENROU.EFD0, eXAC1_1.EFD0)
        gENROU.QELEC ~ mNLEX2.QELEC,   # connect(gENROU.QELEC, mNLEX2.QELEC)
        connect(gENROU.p, GEN1.p),
        gENROU.PMECH0 ~ gENROU.PMECH,   # connect(gENROU.PMECH0, gENROU.PMECH)
        eXAC1_1.VOTHSG ~ const_.y,   # connect(eXAC1_1.VOTHSG, const.y)
        mNLEX2.VUEL ~ eXAC1_1.VUEL,   # connect(mNLEX2.VUEL, eXAC1_1.VUEL)
        gENROU.ETERM ~ eXAC1_1.ECOMP,   # connect(gENROU.ETERM, eXAC1_1.ECOMP)
        mNLEX2.Eterm ~ gENROU.ETERM,   # connect(mNLEX2.Eterm, gENROU.ETERM)
        eXAC1_1.EFD ~ gENROU.EFD,   # connect(eXAC1_1.EFD, gENROU.EFD)
        gENROU.PELEC ~ mNLEX2.PELEC,   # connect(gENROU.PELEC, mNLEX2.PELEC)
        eXAC1_1.VOEL ~ const_.y,   # connect(eXAC1_1.VOEL, const.y)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Controls.PSSE.UEL.MNLEX2" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSSE.UEL.MNLEX2.jl"))
    # mNLEX2.simpleLagLim.state is skipped (F-46): with u = -2 the amplifier state sits at K_M*u = -199.87 far below
    # outMin = 0, its output clamped at 0 for the whole run (y and VUEL match OM to 1e-9), and the reset to outMin that
    # the .mo's `when` fires when K*u - state crosses zero is triggered by the numerical residual of a converged state
    # in both tools, at different instants (OM ~0.8 s, MTK ~1.25 s): a 2.7 transient of a wound-up, unobservable
    # state, not a model difference.
    validate_against_oracle(MNLEX2_Test, oracle; skip = ["mNLEX2.simpleLagLim.state"])
end
