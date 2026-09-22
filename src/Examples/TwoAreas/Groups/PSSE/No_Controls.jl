# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/TwoAreas/Groups/PSSE/No_Controls.mo (package with the four models G1..G4, each extending
# Support/Generator.mo), transcribed by hand from the transcriber drafts (2026-09-14).
# One file for the package, as the .mo: TwoAreas_NoControls_G1..G4 (the name table). Each unit is one
# GENSAL with constant field voltage and mechanical power (`EFD0 -> EFD`, `PMECH0 -> PMECH`) on the template's pin;
# the units differ in H and D (G3: H = 6.175, D = 0; G4: H = 6.175). The causal connects are equalities, in the
# order of each model. Omitted: graphical annotations, displayPF.

@component function TwoAreas_NoControls_G1(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0)
    @named base = TwoAreas_Generator(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    @unpack pwPin = base
    systems = @named begin
        gENSAL = GENSAL(; Tpd0 = 8.0, Tppd0 = 0.03, Tppq0 = 0.05, H = 6.5, Xd = 1.8, Xq = 1.7, Xpd = 0.3, Xppd = 0.25,
            Xppq = 0.25, Xl = 0.2, R_a = 0.0025, D = 0.02, S12 = 0.802, S10 = 0.18600, M_b = 900000000.0, V_b, v_0,
            angle_0, P_0, Q_0, S_b, fn)
    end
    eqs = Equation[
        gENSAL.EFD0 ~ gENSAL.EFD,      # connect(gENSAL.EFD0, gENSAL.EFD)
        gENSAL.PMECH ~ gENSAL.PMECH0,  # connect(gENSAL.PMECH, gENSAL.PMECH0)
        connect(gENSAL.p, pwPin),
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@component function TwoAreas_NoControls_G2(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0)
    @named base = TwoAreas_Generator(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    @unpack pwPin = base
    systems = @named begin
        gENSAL = GENSAL(; Tpd0 = 8.0, Tppd0 = 0.03, Tppq0 = 0.05, H = 6.5, Xd = 1.8, Xq = 1.7, Xpd = 0.3, Xppd = 0.25,
            Xppq = 0.25, Xl = 0.2, R_a = 0.0025, D = 0.02, S12 = 0.802, S10 = 0.18600, M_b = 900000000.0, V_b, v_0,
            angle_0, P_0, Q_0, S_b, fn)
    end
    eqs = Equation[
        gENSAL.EFD ~ gENSAL.EFD0,      # connect(gENSAL.EFD, gENSAL.EFD0)
        gENSAL.PMECH ~ gENSAL.PMECH0,  # connect(gENSAL.PMECH, gENSAL.PMECH0)
        connect(gENSAL.p, pwPin),
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@component function TwoAreas_NoControls_G3(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0)
    @named base = TwoAreas_Generator(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    @unpack pwPin = base
    systems = @named begin
        gENSAL = GENSAL(; Tpd0 = 8.0, Tppd0 = 0.03, Tppq0 = 0.05, D = 0.0, Xd = 1.8, Xq = 1.7, Xpd = 0.3, Xppd = 0.25,
            Xppq = 0.25, Xl = 0.2, H = 6.175, R_a = 0.0025, S12 = 0.802, S10 = 0.18600, M_b = 900000000.0, V_b, v_0,
            P_0, Q_0, angle_0, S_b, fn)
    end
    eqs = Equation[
        gENSAL.PMECH ~ gENSAL.PMECH0,  # connect(gENSAL.PMECH, gENSAL.PMECH0)
        gENSAL.EFD0 ~ gENSAL.EFD,      # connect(gENSAL.EFD0, gENSAL.EFD)
        connect(gENSAL.p, pwPin),
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@component function TwoAreas_NoControls_G4(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0)
    @named base = TwoAreas_Generator(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    @unpack pwPin = base
    systems = @named begin
        gENSAL = GENSAL(; Tpd0 = 8.0, Tppd0 = 0.03, Tppq0 = 0.05, H = 6.175, Xd = 1.8, Xq = 1.7, Xpd = 0.3, Xppd = 0.25,
            Xppq = 0.25, Xl = 0.2, R_a = 0.0025, D = 0.02, S12 = 0.802, S10 = 0.18600, M_b = 900000000.0, V_b, v_0,
            angle_0, P_0, Q_0, S_b, fn)
    end
    eqs = Equation[
        connect(gENSAL.p, pwPin),
        gENSAL.EFD0 ~ gENSAL.EFD,      # connect(gENSAL.EFD0, gENSAL.EFD)
        gENSAL.PMECH ~ gENSAL.PMECH0,  # connect(gENSAL.PMECH, gENSAL.PMECH0)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end
