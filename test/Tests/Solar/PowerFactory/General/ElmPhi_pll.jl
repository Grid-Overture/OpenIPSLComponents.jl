# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# PortTests/Solar/PowerFactory/General/ElmPhi_pll.mo (a Test of this port, not OpenIPSL's: PLAN-12,
# family F), transcribed automatically (2026-09-21); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# The SMIB base and the machine of Tests.Machines.PSSE.GENSAL with the PLL on the FAULT bus, where the base's
# fault at 2 s moves the voltage phasor the most. The PLL draws no current, so it does not change the operating
# point, and its three parameters are inert: PLLEnable is false by default and the .mo says the loop is not
# implemented yet. `ElmPhi_pll` is the model, so the Test function takes the suffix _Test (PLAN-02 rule).
@component function ElmPhi_pll_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack FAULT, GEN1 = base
    systems = @named begin
        gENSAL = GENSAL(; Tpd0 = 5.0, Tppd0 = 0.07, Tppq0 = 0.09, H = 4.28, D = 0.0, Xd = 1.84, Xq = 1.75, Xpd = 0.41, Xppd = 0.2, Xl = 0.12, S10 = 0.11, S12 = 0.39, angle_0 = 0.070492225331847, Xppq = 0.2, R_a = 0.0, M_b = 100000000.0, P_0 = 40000000.0, Q_0 = 5416582.0, v_0 = 1.0, S_b, fn)
        elmPhi_pll = ElmPhi_pll(; angle_0rad = 0.0, omega_0 = 1.0, v_0 = 1.0)
    end
    eqs = Equation[
        gENSAL.PMECH ~ gENSAL.PMECH0,   # connect(gENSAL.PMECH, gENSAL.PMECH0)
        gENSAL.EFD ~ gENSAL.EFD0,   # connect(gENSAL.EFD, gENSAL.EFD0)
        connect(gENSAL.p, GEN1.p),
        connect(elmPhi_pll.p, FAULT.p),
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "PortTests.Solar.PowerFactory.General.ElmPhi_pll" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Solar.PowerFactory.General.ElmPhi_pll.jl"))
    validate_against_oracle(ElmPhi_pll_Test, oracle)
end
