# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/ES/SCRX.mo (extends ES/BaseClasses/BaseExciter.mo)
# Blocks: V_erro = Add3, imLeadLag = LeadLag(K = 1, y_start = VR0/K, T1 = T_AT_B*T_B, T2 = T_B), negCurLogic =
# NegCurLogic(nstartvalue = Efd0, RC_rfd = r_cr_fd), simpleLagLim = SimpleLagLim(K, T_E, y_start = VR0, E_MAX, E_MIN),
# switch1 = Switch, booleanConstant = BooleanConstant(k = C_SWITCH), product = Product, DiffV1 = Add(k2 = -1).
# The causal connects are equalities; the Boolean signal of the switch is Real 0/1. `VR0` is `fixed = false` and
# resolved from inputs (F-33): the `if not C_SWITCH` of the `initial equation` tests a parameter and is decided in
# Julia. Omitted: Icons.VerifiedModel, graphical annotations.

@component function SCRX(; name, T_AT_B = 0.1, T_B = 1, K = 100, T_E = 0.005, E_MIN = -10, E_MAX = 10,
        C_SWITCH = false, r_cr_fd = 10)
    T_AT_B, T_B, K, T_E, E_MIN, E_MAX, r_cr_fd = float.((T_AT_B, T_B, K, T_E, E_MIN, E_MAX, r_cr_fd))
    n = (; K, T_E, E_MIN, E_MAX, r_cr_fd, C_SWITCH, T1 = T_AT_B * T_B, T2 = T_B)
    @named base = BaseExciter()
    @unpack Efd0, V_REF, ECOMP0, DiffV, VUEL, VOEL, EFD, VOTHSG, ECOMP, XADIFD = base
    pars = @parameters begin
        T_AT_B = T_AT_B, [description = "Ratio between regulator numerator (lead) and denominator (lag) time constants"]
        T_B = T_B, [description = "Regulator denominator (lag) time constant (s)"]
        K = K, [description = "Excitation power source output gain"]
        T_E = T_E, [description = "Excitation power source output time constant (s)"]
        E_MIN = E_MIN, [description = "Minimum exciter output"]
        E_MAX = E_MAX, [description = "Maximum exciter output"]
        r_cr_fd = r_cr_fd, [description = "Ratio between crowbar circuit resistance and field circuit resistance"]
        VR0, [guess = 1.0]   # fixed = false, from the initial equation below
    end
    systems = @named begin
        V_erro = Add3()
        imLeadLag = LeadLag(; K = 1, y_start = VR0 / n.K, T1 = n.T1, T2 = n.T2)
        negCurLogic = NegCurLogic(; nstartvalue = Efd0, RC_rfd = n.r_cr_fd)
        simpleLagLim = SimpleLagLim(; K = n.K, T = n.T_E, y_start = VR0, outMax = n.E_MAX, outMin = n.E_MIN)
        switch1 = Switch()
        booleanConstant = BooleanConstant(; k = n.C_SWITCH)
        product = Product()
        DiffV1 = Add(; k2 = -1)
    end
    eqs = Equation[
        V_erro.y ~ imLeadLag.u,              # connect(V_erro.y, imLeadLag.u)
        imLeadLag.y ~ simpleLagLim.u,        # connect(imLeadLag.y, simpleLagLim.u)
        booleanConstant.y ~ switch1.u2,      # connect(booleanConstant.y, switch1.u2)
        product.u2 ~ simpleLagLim.y,         # connect(product.u2, simpleLagLim.y)
        product.y ~ switch1.u3,              # connect(product.y, switch1.u3)
        switch1.u1 ~ simpleLagLim.y,         # connect(switch1.u1, simpleLagLim.y)
        ECOMP ~ DiffV.u2,                    # connect(ECOMP, DiffV.u2)
        DiffV.y ~ V_erro.u2,                 # connect(DiffV.y, V_erro.u2)
        VOTHSG ~ V_erro.u1,                  # connect(VOTHSG, V_erro.u1)
        DiffV1.u2 ~ VOEL,                    # connect(DiffV1.u2, VOEL)
        DiffV1.u1 ~ VUEL,                    # connect(DiffV1.u1, VUEL)
        DiffV1.y ~ V_erro.u3,                # connect(DiffV1.y, V_erro.u3)
        negCurLogic.Efd ~ EFD,               # connect(negCurLogic.Efd, EFD)
        product.u1 ~ DiffV.u2,               # connect(product.u1, DiffV.u2)
        switch1.y ~ negCurLogic.Vd,          # connect(switch1.y, negCurLogic.Vd)
        XADIFD ~ negCurLogic.XadIfd,         # connect(XADIFD, negCurLogic.XadIfd)
    ]
    extend(System(eqs, t, [], pars; name, systems, initial_conditions = Dict(VR0 => missing),
            initialization_eqs = [VR0 ~ (n.C_SWITCH ? Efd0 : Efd0 / ECOMP0), V_REF ~ VR0 / K + ECOMP0]), base)
end
