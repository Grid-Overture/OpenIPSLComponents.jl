# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Controls/PSSE/ES/ESAC2A.mo, transcribed automatically (2026-09-14); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# `ESAC2A` is the exciter (suffix _Test), first Test of IntegratorLimVar (F-22 point 5). `Modelica.Constants.inf` is 1e60.
@component function ESAC2A_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1 = base
    systems = @named begin
        gENROU = GENROU(; Xppd = 0.2, Xppq = 0.2, Xpp = 0.2, Xl = 0.12, angle_0 = 0.070620673811799, Tpd0 = 5.0, Tppd0 = 0.50000E-01, Tppq0 = 0.1, H = 4.0000, D = 0.0, Xd = 1.41, Xq = 1.3500, Xpd = 0.3, S10 = 0.1, S12 = 0.5, Xpq = 0.6, Tpq0 = 0.7, M_b = 100000000.0, P_0 = 39999952.912331, Q_0 = 5416571.3489056, v_0 = 1.0, S_b, fn)
        eSAC2A = ESAC2A(; V_RMAX = 4.0, V_RMIN = -4.0, V_FEMAX = 10.0)
        minusInf = Constant(; k = -OpenIPSLComponents.Modelica.Constants.inf)
        plusInf = Constant(; k = OpenIPSLComponents.Modelica.Constants.inf)
        zero = Constant(; k = 0)
    end
    eqs = Equation[
        eSAC2A.EFD0 ~ gENROU.EFD0,   # connect(eSAC2A.EFD0, gENROU.EFD0)
        gENROU.XADIFD ~ eSAC2A.XADIFD,   # connect(gENROU.XADIFD, eSAC2A.XADIFD)
        eSAC2A.ECOMP ~ gENROU.ETERM,   # connect(eSAC2A.ECOMP, gENROU.ETERM)
        gENROU.PMECH0 ~ gENROU.PMECH,   # connect(gENROU.PMECH0, gENROU.PMECH)
        eSAC2A.EFD ~ gENROU.EFD,   # connect(eSAC2A.EFD, gENROU.EFD)
        connect(gENROU.p, GEN1.p),
        zero.y ~ eSAC2A.VOTHSG,   # connect(zero.y, eSAC2A.VOTHSG)
        plusInf.y ~ eSAC2A.VOEL,   # connect(plusInf.y, eSAC2A.VOEL)
        minusInf.y ~ eSAC2A.VUEL,   # connect(minusInf.y, eSAC2A.VUEL)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Controls.PSSE.ES.ESAC2A" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSSE.ES.ESAC2A.jl"))
    validate_against_oracle(ESAC2A_Test, oracle)
end
