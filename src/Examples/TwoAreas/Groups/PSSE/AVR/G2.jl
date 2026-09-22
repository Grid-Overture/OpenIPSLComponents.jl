# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/TwoAreas/Groups/PSSE/AVR/G2.mo (extends Support/Generator.mo), drafted by
# the transcriber (2026-09-14, --kind base); reviewed by hand. TwoAreas_AVR_G2 (JULIA_NAMES).
# 900 MVA unit of bus 2: a GENROU `g2` with an ESDC1A exciter (K_E = -0.052927, a negative exciter constant, sic);
# VUEL, VOEL and VOTHSG are fed by `non_active_inputs`. The causal connects are equalities.
# Omitted: graphical annotations, displayPF.

@component function TwoAreas_AVR_G2(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0)
    @named base = TwoAreas_Generator(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    @unpack pwPin = base
    systems = @named begin
        g2 = GENROU(; Tpd0 = 8.0, Tppd0 = 0.03, Tppq0 = 0.05, H = 6.5, Xd = 1.8, Xq = 1.7, Xpd = 0.3, Xppd = 0.25, Xppq = 0.25,
            Xl = 0.2, R_a = 0.0025, D = 0.02, S12 = 0.802, S10 = 0.18600, M_b = 900000000.0, V_b, v_0, angle_0, P_0, Q_0,
            Xpq = 0.55, Tpq0 = 0.4, S_b, fn)
        eSDC1A = ESDC1A(; T_R = 0.5, K_A = 20.0, T_A = 0.055, T_B = 1.0, T_C = 1.0, V_RMAX = 4.0, V_RMIN = -4.0,
            K_E = -0.052927, T_E = 0.36, K_F = 0.125, T_F1 = 1.8, E_1 = 1.0, E_2 = 2.0, S_EE_1 = 0.0164, S_EE_2 = 0.0481)
        non_active_inputs = Constant(; k = 0)
    end
    eqs = Equation[
        g2.PMECH ~ g2.PMECH0,                  # connect(g2.PMECH, g2.PMECH0)
        connect(g2.p, pwPin),
        g2.EFD ~ eSDC1A.EFD,                   # connect(g2.EFD, eSDC1A.EFD)
        eSDC1A.EFD0 ~ g2.EFD0,                 # connect(eSDC1A.EFD0, g2.EFD0)
        non_active_inputs.y ~ eSDC1A.VUEL,     # connect(non_active_inputs.y, eSDC1A.VUEL)
        g2.ETERM ~ eSDC1A.ECOMP,               # connect(g2.ETERM, eSDC1A.ECOMP)
        non_active_inputs.y ~ eSDC1A.VOEL,     # connect(non_active_inputs.y, eSDC1A.VOEL)
        non_active_inputs.y ~ eSDC1A.VOTHSG,   # connect(non_active_inputs.y, eSDC1A.VOTHSG)
        g2.XADIFD ~ eSDC1A.XADIFD,             # connect(g2.XADIFD, eSDC1A.XADIFD)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end
