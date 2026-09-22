# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Controls/PSSE/COMP/IEEEVC.mo, transcribed automatically (2026-09-14); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# `IEEEVC` is the compensator (suffix _Test), in series between gENSAL.p and GEN1.p, feeding ESDC1A's ECOMP;
# `const` is the instance `const_`. `Modelica.Constants.inf` is 1e60. Experiment: interval 1e-4 (oracle).
@component function IEEEVC_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1 = base
    systems = @named begin
        gENSAL = GENSAL(; Xppd = 0.36, Xppq = 0.36, Xl = 0.136, angle_0 = 0.070620673811799, Tpd0 = 7.0, Tppd0 = 0.035, Tppq0 = 0.03, H = 3.0, D = 0.0, Xd = 1.16, Xq = 0.81, Xpd = 0.42, S10 = 0.16, S12 = 0.61, M_b = 110000000.0, P_0 = 39999952.912331, Q_0 = 5416571.3489056, v_0 = 1.0, R_a = 0.00323, S_b, fn)
        iEEEVC = IEEEVC(; RC = 0.0, XC = 0.08)
        const_ = Constant(; k = 0)
        eSDC1A = ESDC1A(; T_R = 0.01, K_A = 50.0, V_RMAX = 22.5, V_RMIN = -22.5, K_E = 0.0, T_E = 0.7, T_F1 = 0.45, E_1 = 2.322, E_2 = 3.096, S_EE_1 = 0.221, S_EE_2 = 0.549)
        const1 = Constant(; k = -OpenIPSLComponents.Modelica.Constants.inf)
    end
    eqs = Equation[
        gENSAL.PMECH0 ~ gENSAL.PMECH,   # connect(gENSAL.PMECH0, gENSAL.PMECH)
        const_.y ~ eSDC1A.VOTHSG,   # connect(const.y, eSDC1A.VOTHSG)
        eSDC1A.VOEL ~ eSDC1A.VOTHSG,   # connect(eSDC1A.VOEL, eSDC1A.VOTHSG)
        const1.y ~ eSDC1A.VUEL,   # connect(const1.y, eSDC1A.VUEL)
        gENSAL.XADIFD ~ eSDC1A.XADIFD,   # connect(gENSAL.XADIFD, eSDC1A.XADIFD)
        gENSAL.EFD0 ~ eSDC1A.EFD0,   # connect(gENSAL.EFD0, eSDC1A.EFD0)
        connect(gENSAL.p, iEEEVC.Gen_terminal),
        connect(GEN1.p, iEEEVC.Bus),
        iEEEVC.VCT ~ eSDC1A.ECOMP,   # connect(iEEEVC.VCT, eSDC1A.ECOMP)
        eSDC1A.EFD ~ gENSAL.EFD,   # connect(eSDC1A.EFD, gENSAL.EFD)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Controls.PSSE.COMP.IEEEVC" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSSE.COMP.IEEEVC.jl"))
    validate_against_oracle(IEEEVC_Test, oracle)
end
