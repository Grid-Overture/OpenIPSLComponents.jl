# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/ES/EXNI.mo (extends ES/BaseClasses/BaseExciter.mo)
# Blocks: negCurLogic = NegCurLogic(RC_rfd = r_cr_fd, nstartvalue = Efd0), add3_1 = Add3, derivativeLag =
# Derivative(K_F, T_F1, y_start = 0, InitialOutput), simpleLag1 = SimpleLag(K = 1, T_F2, y_start = 0), add =
# Add(k2 = -1), limiter = Limiter(V_RMAX, V_RMIN), product = Product, switch1 = Switch, booleanConstant =
# BooleanConstant(k = SWITCH), TransducerDelay = SimpleLag(K = 1, T_R, y_start = ECOMP0), Limiters = Add, and the
# protected VR = SimpleLag(K = K_A, T_A, y_start = VR0). The causal connects are equalities; the Boolean signal of
# the switch is Real 0/1 (PLAN-01). `VR0` is `fixed = false` and resolved from inputs (F-33): the `if SWITCH` of the
# `initial equation` tests a parameter, so it is decided in Julia and the selected equation goes to
# `initialization_eqs` (both branches give the same V_REF). Omitted: graphical annotations.

@component function EXNI(; name, T_R = 0.06, K_A = 150, T_A = 0, V_RMAX = 4, V_RMIN = -4, K_F = 0.011, T_F1 = 0.4,
        T_F2 = 0.7, SWITCH = false, r_cr_fd = 10)
    T_R, K_A, T_A, V_RMAX, V_RMIN, K_F, T_F1, T_F2, r_cr_fd = float.((T_R, K_A, T_A, V_RMAX, V_RMIN, K_F, T_F1, T_F2, r_cr_fd))
    n = (; T_R, K_A, T_A, V_RMAX, V_RMIN, K_F, T_F1, T_F2, r_cr_fd, SWITCH)
    @named base = BaseExciter()
    @unpack Efd0, V_REF, ECOMP0, DiffV, VUEL, VOEL, EFD, VOTHSG, ECOMP, XADIFD = base
    pars = @parameters begin
        T_R = T_R, [description = "Regulator input filter time constant (s)"]
        K_A = K_A, [description = "Regulator output gain"]
        T_A = T_A, [description = "Regulator output time constant (s)"]
        V_RMAX = V_RMAX, [description = "Maximum regulator output"]
        V_RMIN = V_RMIN, [description = "Minimum regulator output"]
        K_F = K_F, [description = "Rate feedback excitation system stabilizer gain"]
        T_F1 = T_F1, [description = "Rate feedback excitation system stabilizer first time constant (s)"]
        T_F2 = T_F2, [description = "Rate feedback excitation system stabilizer second time constant (s)"]
        r_cr_fd = r_cr_fd, [description = "Ratio between crowbar circuit resistance and field circuit resistance"]
        VR0, [guess = 1.0]   # fixed = false, from the initial equation below
    end
    systems = @named begin
        negCurLogic = NegCurLogic(; RC_rfd = n.r_cr_fd, nstartvalue = Efd0)
        add3_1 = Add3()
        derivativeLag = Derivative(; k = n.K_F, T = n.T_F1, y_start = 0, initType = :InitialOutput)
        simpleLag1 = SimpleLag(; K = 1, T = n.T_F2, y_start = 0)
        add = Add(; k2 = -1)
        limiter = Limiter(; uMax = n.V_RMAX, uMin = n.V_RMIN)
        product = Product()
        switch1 = Switch()
        booleanConstant = BooleanConstant(; k = n.SWITCH)
        TransducerDelay = SimpleLag(; K = 1, T = n.T_R, y_start = ECOMP0)
        Limiters = Add()
        VR = SimpleLag(; K = n.K_A, T = n.T_A, y_start = VR0)
    end
    eqs = Equation[
        simpleLag1.u ~ derivativeLag.y,      # connect(simpleLag1.u, derivativeLag.y)
        add.y ~ VR.u,                        # connect(add.y, VR.u)
        VR.y ~ limiter.u,                    # connect(VR.y, limiter.u)
        derivativeLag.u ~ limiter.y,         # connect(derivativeLag.u, limiter.y)
        product.u2 ~ limiter.y,              # connect(product.u2, limiter.y)
        product.y ~ switch1.u3,              # connect(product.y, switch1.u3)
        booleanConstant.y ~ switch1.u2,      # connect(booleanConstant.y, switch1.u2)
        negCurLogic.Efd ~ EFD,               # connect(negCurLogic.Efd, EFD)
        ECOMP ~ TransducerDelay.u,           # connect(ECOMP, TransducerDelay.u)
        TransducerDelay.y ~ DiffV.u2,        # connect(TransducerDelay.y, DiffV.u2)
        DiffV.y ~ add3_1.u2,                 # connect(DiffV.y, add3_1.u2)
        VOTHSG ~ add3_1.u1,                  # connect(VOTHSG, add3_1.u1)
        Limiters.u1 ~ VUEL,                  # connect(Limiters.u1, VUEL)
        Limiters.u2 ~ VOEL,                  # connect(Limiters.u2, VOEL)
        Limiters.y ~ add3_1.u3,              # connect(Limiters.y, add3_1.u3)
        add3_1.y ~ add.u1,                   # connect(add3_1.y, add.u1)
        simpleLag1.y ~ add.u2,               # connect(simpleLag1.y, add.u2)
        switch1.y ~ negCurLogic.Vd,          # connect(switch1.y, negCurLogic.Vd)
        switch1.u1 ~ limiter.y,              # connect(switch1.u1, limiter.y)
        product.u1 ~ TransducerDelay.u,      # connect(product.u1, TransducerDelay.u)
        XADIFD ~ negCurLogic.XadIfd,         # connect(XADIFD, negCurLogic.XadIfd)
    ]
    extend(System(eqs, t, [], pars; name, systems, initial_conditions = Dict(VR0 => missing),
            initialization_eqs = [VR0 ~ (n.SWITCH ? Efd0 : Efd0 / ECOMP0), V_REF ~ VR0 / K_A + ECOMP0]), base)
end
