# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/Tutorial/Example_4/BaseModels/GeneratingUnits/GeneratorTurbGovAVRPSS.mo
# (extends Interfaces/Generator.mo). `GeneratorTurbGovAVR` plus a `PSS2A` (T_w1 = 5, so not the degenerate case of
# its own Test, F-48) fed by SPEED and PELEC and driving the exciter's `VOTHSG`; `VOTHSG2` takes the zero constant.
# Named `Example_4_GeneratorTurbGovAVRPSS` (JULIA_NAMES). Omitted: graphical annotations, displayPF.

@component function Example_4_GeneratorTurbGovAVRPSS(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0,
        v_0 = 1, angle_0 = 0)
    @named base = Generator(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    @unpack pwPin = base
    systems = @named begin
        gENROE = GENROE(; v_0, Tpd0 = 5.0, Tppd0 = 0.07, Tppq0 = 0.09, H = 4.28, D = 0.0, Xd = 1.84, Xq = 1.75,
            Xpd = 0.41, Xppd = 0.2, Xppq = 0.2, Xl = 0.12, V_b = 100000.0, M_b = 100000000.0, S10 = 0.11, S12 = 0.39,
            R_a = 0.0, angle_0, P_0, Q_0, Xpq = 0.6, Tpq0 = 0.9, S_b, fn)
        iEEEG1_1 = IEEEG1(; P0 = 0.4, K = 20.0, T_1 = 0.15, T_2 = 0.0, T_3 = 0.2, U_o = 0.1, U_c = -0.1,
            P_MAX = 0.903, P_MIN = 0.0, T_4 = 0.25, K_1 = 0.25, K_2 = 0.0, T_5 = 7.5, K_3 = 0.25, K_4 = 0.0,
            T_6 = 0.4, K_5 = 0.5)
        eSST1A1 = ESST1A(; V_IMAX = 0.3, V_IMIN = -0.3, T_C = 2.0, T_B = 10.0, T_C1 = 0.08, T_B1 = 0.083,
            K_A = 300.0, V_AMAX = 7.0, V_AMIN = -7.0, V_RMAX = 5.2, V_RMIN = -5.2, K_C = 0.38, K_F = 1.0, T_F = 1.0,
            K_LR = 1.0, I_LR = 0.0, T_A = 0.1, T_R = 0.1)
        pSS2A = PSS2A(; T_w1 = 5.0, T_w2 = 5.0, T_6 = 0.0, T_w3 = 5.0, T_w4 = 5.0, T_7 = 5.0, K_S2 = 0.758,
            K_S3 = 1.0, T_8 = 0.12, T_9 = 0.1, K_S1 = 2.0, T_1 = 0.47, T_2 = 0.07, T_3 = 0.47, T_4 = 0.07,
            V_STMAX = 0.1, V_STMIN = -0.1)
        zero = Constant(; k = 0)
        negInf = Constant(; k = -Modelica.Constants.inf)
        posInf = Constant(; k = Modelica.Constants.inf)
    end
    eqs = Equation[
        eSST1A1.EFD ~ gENROE.EFD,            # connect(eSST1A1.EFD, gENROE.EFD)
        pSS2A.VOTHSG ~ eSST1A1.VOTHSG,       # connect(pSS2A.VOTHSG, eSST1A1.VOTHSG)
        gENROE.SPEED ~ iEEEG1_1.SPEED_HP,    # connect(gENROE.SPEED, iEEEG1_1.SPEED_HP)
        gENROE.ETERM ~ eSST1A1.VT,           # connect(gENROE.ETERM, eSST1A1.VT)
        gENROE.EFD0 ~ eSST1A1.EFD0,          # connect(gENROE.EFD0, eSST1A1.EFD0)
        zero.y ~ eSST1A1.VUEL,               # connect(zero.y, eSST1A1.VUEL)
        gENROE.XADIFD ~ eSST1A1.XADIFD,      # connect(gENROE.XADIFD, eSST1A1.XADIFD)
        gENROE.PELEC ~ pSS2A.V_S2,           # connect(gENROE.PELEC, pSS2A.V_S2)
        negInf.y ~ eSST1A1.VUEL2,            # connect(negInf.y, eSST1A1.VUEL2)
        posInf.y ~ eSST1A1.VOEL,             # connect(posInf.y, eSST1A1.VOEL)
        iEEEG1_1.PMECH_HP ~ gENROE.PMECH,    # connect(iEEEG1_1.PMECH_HP, gENROE.PMECH)
        connect(gENROE.p, pwPin),
        eSST1A1.VUEL3 ~ negInf.y,            # connect(eSST1A1.VUEL3, negInf.y)
        eSST1A1.VOTHSG2 ~ zero.y,            # connect(eSST1A1.VOTHSG2, zero.y)
        eSST1A1.ECOMP ~ gENROE.ETERM,        # connect(eSST1A1.ECOMP, gENROE.ETERM)
        pSS2A.V_S1 ~ gENROE.SPEED,           # connect(pSS2A.V_S1, gENROE.SPEED)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end
