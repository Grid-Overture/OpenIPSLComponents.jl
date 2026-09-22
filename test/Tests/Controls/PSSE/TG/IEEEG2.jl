# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Controls/PSSE/TG/IEEEG2.mo, transcribed by hand (2026-09-15).
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# GENSAL with no exciter (EFD0 <- EFD). The experiment annotation asks for 100 000 intervals; the oracle is still the
# usual 21 instants.
@component function IEEEG2_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1 = base
    systems = @named begin
        gENSAL = GENSAL(; P_0 = 40000000.0, Q_0 = 5415812.0, angle_0 = 0.070619983433093, M_b = 115000000.0, Tpd0 = 4.1, Tppd0 = 0.05, Tppq0 = 0.06, H = 1.4631, D = 0.0, Xd = 0.852, Xq = 0.61, Xpd = 0.395, Xppd = 0.293, Xppq = 0.293, Xl = 0.237, S10 = 0.11, S12 = 0.48, v_0 = 1.0, S_b, fn)
        iEEEG2 = IEEEG2(; T_4 = 1.0, P_MAX = 1.19, P_MIN = 0.0)
    end
    eqs = Equation[
        connect(gENSAL.p, GEN1.p),
        gENSAL.EFD0 ~ gENSAL.EFD,       # connect(gENSAL.EFD0, gENSAL.EFD)
        gENSAL.SPEED ~ iEEEG2.SPEED,    # connect(gENSAL.SPEED, iEEEG2.SPEED)
        gENSAL.PMECH0 ~ iEEEG2.PMECH0,  # connect(gENSAL.PMECH0, iEEEG2.PMECH0)
        iEEEG2.PMECH ~ gENSAL.PMECH,    # connect(iEEEG2.PMECH, gENSAL.PMECH)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Controls.PSSE.TG.IEEEG2" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSSE.TG.IEEEG2.jl"))
    validate_against_oracle(IEEEG2_Test, oracle)
end
