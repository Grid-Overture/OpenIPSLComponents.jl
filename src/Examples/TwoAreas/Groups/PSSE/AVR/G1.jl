# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/TwoAreas/Groups/PSSE/AVR/G1.mo (extends Support/Generator.mo), drafted by
# the transcriber (2026-09-14, --kind base); reviewed by hand. TwoAreas_AVR_G1 (JULIA_NAMES).
# 900 MVA unit of bus 1: a GENROU `g1` with a SEXS exciter; VUEL, VOEL and VOTHSG are fed by the Constant
# `non_active_inputs`. The causal connects are equalities. Omitted: graphical annotations, displayPF.

@component function TwoAreas_AVR_G1(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0)
    @named base = TwoAreas_Generator(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    @unpack pwPin = base
    systems = @named begin
        g1 = GENROU(; Tpd0 = 8.0, Tppd0 = 0.03, Tppq0 = 0.05, H = 6.5, Xd = 1.8, Xq = 1.7, Xpd = 0.3, Xppd = 0.25, Xppq = 0.25,
            Xl = 0.2, R_a = 0.0025, D = 0.02, S12 = 0.802, S10 = 0.18600, M_b = 900000000.0, V_b, v_0, angle_0, P_0, Q_0,
            Xpq = 0.55, Tpq0 = 0.4, S_b, fn)
        sEXS = SEXS(; T_AT_B = 1.0, T_B = 1.0, K = 200.0, T_E = 0.01, E_MIN = 0.0, E_MAX = 4.0)
        non_active_inputs = Constant(; k = 0)
    end
    eqs = Equation[
        g1.PMECH ~ g1.PMECH0,                # connect(g1.PMECH, g1.PMECH0)
        connect(g1.p, pwPin),
        sEXS.EFD ~ g1.EFD,                   # connect(sEXS.EFD, g1.EFD)
        sEXS.EFD0 ~ g1.EFD0,                 # connect(sEXS.EFD0, g1.EFD0)
        sEXS.VOEL ~ non_active_inputs.y,     # connect(sEXS.VOEL, non_active_inputs.y)
        sEXS.VOTHSG ~ non_active_inputs.y,   # connect(sEXS.VOTHSG, non_active_inputs.y)
        sEXS.VUEL ~ non_active_inputs.y,     # connect(sEXS.VUEL, non_active_inputs.y)
        g1.ETERM ~ sEXS.ECOMP,               # connect(g1.ETERM, sEXS.ECOMP)
        g1.XADIFD ~ sEXS.XADIFD,             # connect(g1.XADIFD, sEXS.XADIFD)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end
