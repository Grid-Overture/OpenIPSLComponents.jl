# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/Microgrids/UniversityCampus/CampusA/GenerationGroups/STG1/STG1MachineComplete.mo (extends OpenIPSL.Interfaces.Generator)
# Generation unit STG1 of `CampusGridA`: a `GENROU` with its excitation system, its turbine governor and a
# `DisabledPSS`, plus the `IEEEVC` voltage compensator between the machine pin and the exciter.
# The four `replaceable` components have **no `redeclare` in any user**, so they are written with their concrete
# class and the unit takes no `mods` (rule 6: nothing just in case).
# `guData(redeclare record GUnitDynamics = DynParamRecords.STG1)` is fixed in the .mo itself, not a keyword of the
# unit: it is the constant `guData = (; guDynamics = CampusA_STG1)` here, so the `.mo`'s own
# `guData.guDynamics.<sub>.<field>` text is literal.
# `const` is a Julia keyword, so the Constant instances are `const_`/`const1`.
# Omitted: graphical annotations, displayPF.

@component function STG1MachineComplete(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0)
    # `guData(redeclare record GUnitDynamics = DynParamRecords.STG1)` of the .mo, so that every
    # parameter below reads `guData.guDynamics.<sub>.<field>` exactly as the .mo writes it
    guData = (; guDynamics = CampusA_STG1)
    @named base = Generator(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    @unpack pwPin = base
    systems = @named begin
        machine = GENROU(; V_b = V_b, Tpd0 = guData.guDynamics.machine.Tpd0, Tppd0 = guData.guDynamics.machine.Tppd0, Tpq0 = guData.guDynamics.machine.Tpq0, Tppq0 = guData.guDynamics.machine.Tppq0, D = guData.guDynamics.machine.D, Xd = guData.guDynamics.machine.Xd, Xq = guData.guDynamics.machine.Xq, Xpd = guData.guDynamics.machine.Xpd, Xpq = guData.guDynamics.machine.Xpq, Xppd = guData.guDynamics.machine.Xppd, Xl = guData.guDynamics.machine.Xl, S10 = guData.guDynamics.machine.S10, S12 = guData.guDynamics.machine.S12, angle_0 = angle_0, Xppq = guData.guDynamics.machine.Xppq, R_a = guData.guDynamics.machine.R_a, Xpp = guData.guDynamics.machine.Xpp, H = guData.guDynamics.machine.H, M_b = guData.guDynamics.machine.M_b, P_0 = P_0, Q_0 = Q_0, v_0 = v_0)
        exciter = ESST2A(; T_R = guData.guDynamics.excSystem.T_R, V_RMAX = guData.guDynamics.excSystem.V_RMAX, V_RMIN = guData.guDynamics.excSystem.V_RMIN, K_A = guData.guDynamics.excSystem.K_A, T_A = guData.guDynamics.excSystem.T_A, K_P = guData.guDynamics.excSystem.K_P, K_I = guData.guDynamics.excSystem.K_I, K_C = guData.guDynamics.excSystem.K_C, K_F = guData.guDynamics.excSystem.K_F, T_F = guData.guDynamics.excSystem.T_F, K_E = guData.guDynamics.excSystem.K_E, T_E = guData.guDynamics.excSystem.T_E, EFD_MAX = guData.guDynamics.excSystem.EFD_MAX)
        const_ = Constant(; k = -Modelica.Constants.inf)
        const1 = Constant(; k = 0)
        governor = TGOV1(; R = guData.guDynamics.tg.R, D_t = guData.guDynamics.tg.D_t, T_1 = guData.guDynamics.tg.T_1, T_2 = guData.guDynamics.tg.T_2, T_3 = guData.guDynamics.tg.T_3, V_MAX = guData.guDynamics.tg.V_MAX, V_MIN = guData.guDynamics.tg.V_MIN)
        iEEEVC = IEEEVC(; RC = 0, XC = 0.05)
        pss = DisabledPSS()
    end
    eqs = Equation[
        pss.V_S2 ~ governor.PMECH0,   # connect(pss.V_S2, governor.PMECH0)
        pss.V_S1 ~ machine.SPEED,   # connect(pss.V_S1, machine.SPEED)
        pss.VOTHSG ~ exciter.VOTHSG,   # connect(pss.VOTHSG, exciter.VOTHSG)
        exciter.EFD ~ machine.EFD,   # connect(exciter.EFD, machine.EFD)
        exciter.XADIFD ~ machine.XADIFD,   # connect(exciter.XADIFD, machine.XADIFD)
        machine.EFD0 ~ exciter.EFD0,   # connect(machine.EFD0, exciter.EFD0)
        const_.y ~ exciter.VUEL,   # connect(const_.y, exciter.VUEL)
        const1.y ~ exciter.VOEL,   # connect(const1.y, exciter.VOEL)
        governor.PMECH ~ machine.PMECH,   # connect(governor.PMECH, machine.PMECH)
        governor.SPEED ~ machine.SPEED,   # connect(governor.SPEED, machine.SPEED)
        machine.PMECH0 ~ governor.PMECH0,   # connect(machine.PMECH0, governor.PMECH0)
        connect(exciter.Bus, pwPin),
        connect(iEEEVC.Gen_terminal, exciter.Gen_terminal),
        connect(iEEEVC.Bus, machine.p),
        iEEEVC.VCT ~ exciter.ECOMP,   # connect(iEEEVC.VCT, exciter.ECOMP)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end
