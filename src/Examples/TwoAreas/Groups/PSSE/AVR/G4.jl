# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/TwoAreas/Groups/PSSE/AVR/G4.mo (extends Support/Generator.mo), drafted by
# the transcriber (2026-09-14, --kind base); reviewed by hand. TwoAreas_AVR_G4 (JULIA_NAMES).
# 900 MVA unit of bus 4: a GENROU in an instance named `gENSAL` (sic) with an ESDC1A exciter (K_E = -0.072); VUEL
# and VOTHSG are fed by `non_active_inputs` and VOEL by VUEL. The causal connects are equalities.
# Omitted: graphical annotations, displayPF.

@component function TwoAreas_AVR_G4(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0)
    @named base = TwoAreas_Generator(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    @unpack pwPin = base
    systems = @named begin
        gENSAL = GENROU(; Tpd0 = 8.0, Tppd0 = 0.03, Tppq0 = 0.05, H = 6.175, Xd = 1.8, Xq = 1.7, Xpd = 0.3, Xppd = 0.25,
            Xppq = 0.25, Xl = 0.2, R_a = 0.0025, D = 0.02, S12 = 0.802, S10 = 0.18600, V_b, v_0, angle_0, P_0, Q_0,
            Xpq = 0.55, Tpq0 = 0.4, M_b = 900000000.0, S_b, fn)
        eSDC1A = ESDC1A(; T_R = 0.05, K_A = 20.0, T_A = 0.055, T_B = 1.0, T_C = 1.0, V_RMAX = 4.0, V_RMIN = -4.0,
            K_E = -0.072, T_E = 0.36, K_F = 0.125, T_F1 = 1.8, E_1 = 1.0, E_2 = 2.0, S_EE_1 = 0.0164, S_EE_2 = 0.0481)
        non_active_inputs = Constant(; k = 0)
    end
    eqs = Equation[
        connect(gENSAL.p, pwPin),
        gENSAL.PMECH ~ gENSAL.PMECH0,          # connect(gENSAL.PMECH, gENSAL.PMECH0)
        eSDC1A.EFD ~ gENSAL.EFD,               # connect(eSDC1A.EFD, gENSAL.EFD)
        eSDC1A.EFD0 ~ gENSAL.EFD0,             # connect(eSDC1A.EFD0, gENSAL.EFD0)
        non_active_inputs.y ~ eSDC1A.VUEL,     # connect(non_active_inputs.y, eSDC1A.VUEL)
        eSDC1A.VOEL ~ eSDC1A.VUEL,             # connect(eSDC1A.VOEL, eSDC1A.VUEL)
        gENSAL.ETERM ~ eSDC1A.ECOMP,           # connect(gENSAL.ETERM, eSDC1A.ECOMP)
        non_active_inputs.y ~ eSDC1A.VOTHSG,   # connect(non_active_inputs.y, eSDC1A.VOTHSG)
        gENSAL.XADIFD ~ eSDC1A.XADIFD,         # connect(gENSAL.XADIFD, eSDC1A.XADIFD)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end
