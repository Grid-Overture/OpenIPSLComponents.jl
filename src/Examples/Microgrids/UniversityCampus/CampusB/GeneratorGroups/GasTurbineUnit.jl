# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/Microgrids/UniversityCampus/CampusB/GeneratorGroups/GT.mo (extends OpenIPSL.Interfaces.Generator)
# Generation unit GT of `CampusGridB`: a `GENROE` with its excitation system and its turbine governor.
# The three `replaceable` components have **no `redeclare` in any user**, so they are written with their concrete
# class and the unit takes no `mods` (rule 6).
# `gUData(redeclare record GUnitDynamics = DynParamRecords.GT)` is fixed in the .mo itself, so it is the
# constant `gUData = (; guDynamics = CampusB_GT)` here and every parameter reads it exactly as the .mo does.
# Names as in the .mo: the steam unit calls its machine `baseMachine` and its governor `baseGovernor`, while the
# gas unit calls them `machine` and `governor` (sic); both call the exciter `baseExciter`.
# `zero` is a `Base` function in Julia, so the Constant instance is `zero_`.
# **No OpenModelica reference** (F-63). Omitted: graphical annotations, displayPF.

@component function GasTurbineUnit(; name, S_b = 100e6, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0, V_b = 400e3)
    # `gUData.guDynamics` of the .mo
    gUData = (; guDynamics = CampusB_GT)
    @named base = Generator(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    @unpack pwPin = base
    systems = @named begin
        zero_ = Constant(; k = 0)
        machine = GENROE(; V_b = V_b, Tpd0 = gUData.guDynamics.machine.Tpd0, Tppd0 = gUData.guDynamics.machine.Tppd0, Tpq0 = gUData.guDynamics.machine.Tpq0, Tppq0 = gUData.guDynamics.machine.Tppq0, D = gUData.guDynamics.machine.D, Xd = gUData.guDynamics.machine.Xd, Xq = gUData.guDynamics.machine.Xq, Xpd = gUData.guDynamics.machine.Xpd, Xpq = gUData.guDynamics.machine.Xpq, Xppd = gUData.guDynamics.machine.Xppd, Xl = gUData.guDynamics.machine.Xl, S10 = gUData.guDynamics.machine.S10, S12 = gUData.guDynamics.machine.S12, angle_0 = angle_0, Xppq = gUData.guDynamics.machine.Xppq, R_a = gUData.guDynamics.machine.R_a, Xpp = gUData.guDynamics.machine.Xpp, H = gUData.guDynamics.machine.H, M_b = gUData.guDynamics.machine.M_b, P_0 = P_0, Q_0 = Q_0, v_0 = v_0)
        governor = GAST(; R = gUData.guDynamics.tg.R, T_1 = gUData.guDynamics.tg.T_1, T_2 = gUData.guDynamics.tg.T_2, T_3 = gUData.guDynamics.tg.T_3, AT = gUData.guDynamics.tg.AT, K_T = gUData.guDynamics.tg.K_T, V_MAX = gUData.guDynamics.tg.V_MAX, V_MIN = gUData.guDynamics.tg.V_MIN, D_turb = gUData.guDynamics.tg.D_turb)
        baseExciter = EXAC1(; T_R = gUData.guDynamics.excSystem.T_R, T_B = gUData.guDynamics.excSystem.T_B, T_C = gUData.guDynamics.excSystem.T_C, K_A = gUData.guDynamics.excSystem.K_A, T_A = gUData.guDynamics.excSystem.T_A, V_RMAX = gUData.guDynamics.excSystem.V_RMAX, V_RMIN = gUData.guDynamics.excSystem.V_RMIN, T_E = gUData.guDynamics.excSystem.T_E, K_F = gUData.guDynamics.excSystem.K_F, T_F = gUData.guDynamics.excSystem.T_F, K_C = gUData.guDynamics.excSystem.K_C, K_D = gUData.guDynamics.excSystem.K_D, K_E = gUData.guDynamics.excSystem.K_E, E_1 = gUData.guDynamics.excSystem.E_1, E_2 = gUData.guDynamics.excSystem.E_2, S_EE_1 = gUData.guDynamics.excSystem.S_EE_1, S_EE_2 = gUData.guDynamics.excSystem.S_EE_2)
    end
    eqs = Equation[
        zero_.y ~ baseExciter.VOTHSG,   # connect(zero.y, baseExciter.VOTHSG)
        baseExciter.VUEL ~ zero_.y,   # connect(baseExciter.VUEL, zero.y)
        baseExciter.VOEL ~ zero_.y,   # connect(baseExciter.VOEL, zero.y)
        machine.PMECH ~ governor.PMECH,   # connect(machine.PMECH, governor.PMECH)
        machine.EFD ~ baseExciter.EFD,   # connect(machine.EFD, baseExciter.EFD)
        machine.SPEED ~ governor.SPEED,   # connect(machine.SPEED, governor.SPEED)
        machine.PMECH0 ~ governor.PMECH0,   # connect(machine.PMECH0, governor.PMECH0)
        connect(machine.p, pwPin),
        machine.XADIFD ~ baseExciter.XADIFD,   # connect(machine.XADIFD, baseExciter.XADIFD)
        machine.EFD0 ~ baseExciter.EFD0,   # connect(machine.EFD0, baseExciter.EFD0)
        machine.ETERM ~ baseExciter.ECOMP,   # connect(machine.ETERM, baseExciter.ECOMP)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end
