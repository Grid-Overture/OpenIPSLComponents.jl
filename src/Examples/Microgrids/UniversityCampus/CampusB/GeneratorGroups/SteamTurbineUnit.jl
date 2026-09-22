# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/Microgrids/UniversityCampus/CampusB/GeneratorGroups/ST.mo (extends OpenIPSL.Interfaces.Generator(V_b = 13800))
# Generation unit ST of `CampusGridB`: a `GENROE` with its excitation system and its turbine governor.
# The three `replaceable` components have **no `redeclare` in any user**, so they are written with their concrete
# class and the unit takes no `mods` (rule 6).
# `gUData(redeclare record GUnitDynamics = DynParamRecords.ST)` is fixed in the .mo itself, so it is the
# constant `gUData = (; guDynamics = CampusB_ST)` here and every parameter reads it exactly as the .mo does.
# Names as in the .mo: the steam unit calls its machine `baseMachine` and its governor `baseGovernor`, while the
# gas unit calls them `machine` and `governor` (sic); both call the exciter `baseExciter`.
# `zero` is a `Base` function in Julia, so the Constant instance is `zero_`.
# **No OpenModelica reference** (F-63). Omitted: graphical annotations, displayPF.

@component function SteamTurbineUnit(; name, S_b = 100e6, V_b = 13800.0, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0)
    # `gUData.guDynamics` of the .mo
    gUData = (; guDynamics = CampusB_ST)
    @named base = Generator(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    @unpack pwPin = base
    systems = @named begin
        baseMachine = GENROE(; M_b = gUData.guDynamics.machine.M_b, Tpd0 = gUData.guDynamics.machine.Tpd0, Tppd0 = gUData.guDynamics.machine.Tppd0, Tppq0 = gUData.guDynamics.machine.Tppq0, H = gUData.guDynamics.machine.H, D = gUData.guDynamics.machine.D, Xd = gUData.guDynamics.machine.Xd, Xq = gUData.guDynamics.machine.Xq, Xpd = gUData.guDynamics.machine.Xpd, Xppd = gUData.guDynamics.machine.Xppd, Xppq = gUData.guDynamics.machine.Xppq, Xl = gUData.guDynamics.machine.Xl, S10 = gUData.guDynamics.machine.S10, S12 = gUData.guDynamics.machine.S12, R_a = gUData.guDynamics.machine.R_a, Xpq = gUData.guDynamics.machine.Xpq, Tpq0 = gUData.guDynamics.machine.Tpq0, Xpp = gUData.guDynamics.machine.Xpp)
        baseExciter = EXST1(; T_R = gUData.guDynamics.excSystem.T_R, V_IMAX = gUData.guDynamics.excSystem.V_IMAX, V_IMIN = gUData.guDynamics.excSystem.V_IMIN, T_C = gUData.guDynamics.excSystem.T_C, T_B = gUData.guDynamics.excSystem.T_B, K_A = gUData.guDynamics.excSystem.K_A, T_A = gUData.guDynamics.excSystem.T_A, V_RMAX = gUData.guDynamics.excSystem.V_RMAX, V_RMIN = gUData.guDynamics.excSystem.V_RMIN, K_C = gUData.guDynamics.excSystem.K_C, K_F = gUData.guDynamics.excSystem.K_F, T_F = gUData.guDynamics.excSystem.T_F)
        baseGovernor = TGOV1(; R = gUData.guDynamics.tg.R, D_t = gUData.guDynamics.tg.D_t, T_1 = gUData.guDynamics.tg.T_1, T_2 = gUData.guDynamics.tg.T_2, T_3 = gUData.guDynamics.tg.T_3, V_MAX = gUData.guDynamics.tg.V_MAX, V_MIN = gUData.guDynamics.tg.V_MIN)
        zero_ = Constant(; k = 0)
    end
    eqs = Equation[
        connect(baseMachine.p, pwPin),
        baseExciter.EFD ~ baseMachine.EFD,   # connect(baseExciter.EFD, baseMachine.EFD)
        baseGovernor.PMECH ~ baseMachine.PMECH,   # connect(baseGovernor.PMECH, baseMachine.PMECH)
        zero_.y ~ baseExciter.VOTHSG,   # connect(zero.y, baseExciter.VOTHSG)
        baseExciter.VUEL ~ zero_.y,   # connect(baseExciter.VUEL, zero.y)
        baseExciter.VOEL ~ zero_.y,   # connect(baseExciter.VOEL, zero.y)
        baseMachine.XADIFD ~ baseExciter.XADIFD,   # connect(baseMachine.XADIFD, baseExciter.XADIFD)
        baseMachine.ETERM ~ baseExciter.ECOMP,   # connect(baseMachine.ETERM, baseExciter.ECOMP)
        baseMachine.EFD0 ~ baseExciter.EFD0,   # connect(baseMachine.EFD0, baseExciter.EFD0)
        baseMachine.SPEED ~ baseGovernor.SPEED,   # connect(baseMachine.SPEED, baseGovernor.SPEED)
        baseMachine.PMECH0 ~ baseGovernor.PMECH0,   # connect(baseMachine.PMECH0, baseGovernor.PMECH0)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end
