# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/OpenCPS/Generators/G1.mo (extends Electrical/Essentials/pfComponent.mo)
# 24 kV / 100 MVA unit of bus BG1 of the OpenCPS bench: GENSAL + SEXS + HYGOV (the governor with all its MSL
# defaults), with `non_active_inputs(k = 0)` on the SEXS's VOTHSG, VUEL and VOEL. The pin is `conn`.
# Named `OpenCPS_G1` (JULIA_NAMES): `G1` is already several other things in the package.
# Omitted: graphical annotations, displayPF.

@component function OpenCPS_G1(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0)
    @named base = pfComponent(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    systems = @named begin
        conn = PwPin()
        gen = GENSAL(; M_b = 100e6, Tpd0 = 5, Tppd0 = 0.07, Tppq0 = 0.09, H = 4.28, D = 0, Xd = 1.84, Xq = 1.75,
            Xpd = 0.41, Xppd = 0.2, Xl = 0.12, S10 = 0.11, S12 = 0.39, Xppq = 0.2, R_a = 0,
            V_b, v_0, angle_0, P_0, Q_0, S_b, fn)
        sEXS = SEXS(; T_AT_B = 0.1, T_B = 1, K = 100, T_E = 0.1, E_MIN = -10, E_MAX = 10)
        hYGOV = HYGOV()
        non_active_inputs = Constant(; k = 0)
    end
    eqs = Equation[
        connect(gen.p, conn),
        sEXS.EFD0 ~ gen.EFD0,               # connect(sEXS.EFD0, gen.EFD0)
        sEXS.ECOMP ~ gen.ETERM,             # connect(sEXS.ECOMP, gen.ETERM)
        hYGOV.SPEED ~ gen.SPEED,            # connect(hYGOV.SPEED, gen.SPEED)
        hYGOV.PMECH0 ~ gen.PMECH0,          # connect(hYGOV.PMECH0, gen.PMECH0)
        sEXS.VOTHSG ~ non_active_inputs.y,  # connect(non_active_inputs.y, sEXS.VOTHSG)
        gen.PMECH ~ hYGOV.PMECH,            # connect(hYGOV.PMECH, gen.PMECH)
        gen.EFD ~ sEXS.EFD,                 # connect(sEXS.EFD, gen.EFD)
        sEXS.XADIFD ~ gen.XADIFD,           # connect(gen.XADIFD, sEXS.XADIFD)
        sEXS.VUEL ~ non_active_inputs.y,    # connect(non_active_inputs.y, sEXS.VUEL)
        sEXS.VOEL ~ non_active_inputs.y,    # connect(non_active_inputs.y, sEXS.VOEL)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end
