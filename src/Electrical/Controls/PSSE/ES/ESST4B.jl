# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/ES/ESST4B.mo (extends ES/BaseClasses/BaseExciter.mo)
# Blocks: lV_Gate = LV_GATE, product = Product, VA = SimpleLag(K = 1, T_A, y_start = VR0), VR1 = LimIntegrator(
# V_RMAX/K_PR, V_RMIN/K_PR, k = K_IR, InitialOutput, y_start = VR0), Gain1 = Gain(K_PR), limiter = Limiter(V_RMAX,
# V_RMIN), add = Add, add1 = Add(k1 = -1), gain = Gain(K_G), VM1 = LimIntegrator(V_MMAX/K_PM, V_MMIN/K_PM, k = K_IM,
# InitialOutput, y_start = VA0), Gain2 = Gain(K_PM), limiter1 = Limiter(V_MMAX, V_MMIN), add2 = Add, maxLimiter =
# Limiter(uMin = -inf, uMax = V_BMAX), add3_1 = Add3, TransducerDelay = SimpleLag(K = 1, T_R, y_start = ECOMP0),
# rectifierCommutationVoltageDrop = RectifierCommutationVoltageDrop(K_C); two PwPin (Gen_terminal, Bus) connected to
# each other inside the model (pass-through). The protected RealOutput VE is a plain variable; the protected Complex
# V_T, I_T are aliases of the Gen_terminal pin and K_P_comp = K_P (cos THETAP + j sin THETAP) is Julia complex
# arithmetic before `@parameters`: VE = |K_P_comp V_T + j (K_I + K_P_comp X_L) I_T| is expanded by hand. The six
# protected `fixed = false` parameters are resolved from inputs (F-33); the `if` chain on IN0 (an initialization
# unknown) is an `ifelse` chain with the square root guarded. Omitted: Icons.VerifiedModel, graphical annotations.

@component function ESST4B(; name, T_R = 0.3, K_PR = 2.97, K_IR = 2.97, V_RMAX = 1, V_RMIN = -0.87, T_A = 0.01, K_PM = 1,
        K_IM = 0.2, V_MMAX = 1, V_MMIN = -0.87, K_G = 0.1, K_P = 6.73, K_I = 0.1, V_BMAX = 8.41, K_C = 0.1, X_L = 0, THETAP = 0)
    T_R, K_PR, K_IR, V_RMAX, V_RMIN, T_A, K_PM, K_IM, V_MMAX, V_MMIN, K_G, K_P, K_I, V_BMAX, K_C, X_L, THETAP =
        float.((T_R, K_PR, K_IR, V_RMAX, V_RMIN, T_A, K_PM, K_IM, V_MMAX, V_MMIN, K_G, K_P, K_I, V_BMAX, K_C, X_L, THETAP))
    n = (; T_R, K_PR, K_IR, V_RMAX, V_RMIN, T_A, K_PM, K_IM, V_MMAX, V_MMIN, K_G, K_P, K_I, V_BMAX, K_C, X_L, THETAP)
    K_P_comp = K_P * cos(THETAP) + im * K_P * sin(THETAP)
    Z = im * (K_I + K_P_comp * X_L)          # the coefficient of I_T
    a, b, Zr, Zi = real(K_P_comp), imag(K_P_comp), real(Z), imag(Z)
    @named base = BaseExciter()
    @unpack Efd0, V_REF, ECOMP0, DiffV, VUEL, VOEL, EFD, VOTHSG, ECOMP, XADIFD = base
    pars = @parameters begin
        T_R = T_R, [description = "Regulator input filter time constant (s)"]
        K_PR = K_PR, [description = "Voltage regulator proportional gain"]
        K_IR = K_IR, [description = "Voltage regulator integral gain (1/s)"]
        V_RMAX = V_RMAX, [description = "Maximum regulator output"]
        V_RMIN = V_RMIN, [description = "Minimum regulator output"]
        T_A = T_A, [description = "Thyristor bridge firing control equivalent time constant (s)"]
        K_PM = K_PM, [description = "Forward proportional gain of inner loop field regulator"]
        K_IM = K_IM, [description = "Forward integral gain of inner loop field regulator (1/s)"]
        V_MMAX = V_MMAX, [description = "Maximum output of field current regulator"]
        V_MMIN = V_MMIN, [description = "Minimum output of field current regulator"]
        K_G = K_G, [description = "Feedback gain of field current regulator"]
        K_P = K_P, [description = "Potential circuit (voltage) gain coefficient"]
        K_I = K_I, [description = "Compound circuit (current) gain coefficient"]
        V_BMAX = V_BMAX, [description = "Maximum available exciter voltage"]
        K_C = K_C, [description = "Rectifier loading factor proportional to commutating reactance"]
        X_L = X_L, [description = "Reactance associated with potential source"]
        THETAP = THETAP, [description = "Potential circuit phase angle (rad)"]
        Ifd0, [guess = 1.0]   # fixed = false, from the initial equations below
        IN0, [guess = 0.1]
        VB0, [guess = 1.0]
        VA0, [guess = 1.0]
        VR0, [guess = 0.1]
        VE0, [guess = 1.0]
    end
    systems = @named begin
        lV_Gate = LV_GATE()
        product = Product()
        VA = SimpleLag(; K = 1, T = n.T_A, y_start = VR0)
        VR1 = LimIntegrator(; outMax = n.V_RMAX / n.K_PR, outMin = n.V_RMIN / n.K_PR, k = n.K_IR, initType = :InitialOutput, y_start = VR0)
        Gain1 = Gain(; k = n.K_PR)
        limiter = Limiter(; uMax = n.V_RMAX, uMin = n.V_RMIN)
        add = Add()
        add1 = Add(; k1 = -1)
        gain = Gain(; k = n.K_G)
        VM1 = LimIntegrator(; outMax = n.V_MMAX / n.K_PM, outMin = n.V_MMIN / n.K_PM, k = n.K_IM, initType = :InitialOutput, y_start = VA0)
        Gain2 = Gain(; k = n.K_PM)
        limiter1 = Limiter(; uMax = n.V_MMAX, uMin = n.V_MMIN)
        add2 = Add()
        maxLimiter = Limiter(; uMin = -Modelica.Constants.inf, uMax = n.V_BMAX)
        Gen_terminal = PwPin()
        Bus = PwPin()
        add3_1 = Add3()
        TransducerDelay = SimpleLag(; K = 1, T = n.T_R, y_start = ECOMP0)
        rectifierCommutationVoltageDrop = RectifierCommutationVoltageDrop(; K_C = n.K_C)
    end
    vars = @variables begin
        VE(t)
    end
    vr, vi, ir, ii = Gen_terminal.vr, Gen_terminal.vi, Gen_terminal.ir, Gen_terminal.ii
    rcv = rectifierCommutationVoltageDrop
    eqs = Equation[
        # VE = abs(K_P_comp*V_T + j*(K_I + K_P_comp*X_L)*I_T), V_T = vr + j vi, I_T = ir + j ii
        VE ~ sqrt((a * vr - b * vi + Zr * ir - Zi * ii)^2 + (a * vi + b * vr + Zr * ii + Zi * ir)^2),
        add.y ~ limiter.u,                   # connect(add.y, limiter.u)
        maxLimiter.y ~ product.u2,           # connect(maxLimiter.y, product.u2)
        lV_Gate.y ~ product.u1,              # connect(lV_Gate.y, product.u1)
        add3_1.y ~ Gain1.u,                  # connect(add3_1.y, Gain1.u)
        VR1.u ~ Gain1.u,                     # connect(VR1.u, Gain1.u)
        ECOMP ~ TransducerDelay.u,           # connect(ECOMP, TransducerDelay.u)
        TransducerDelay.y ~ DiffV.u2,        # connect(TransducerDelay.y, DiffV.u2)
        DiffV.y ~ add3_1.u2,                 # connect(DiffV.y, add3_1.u2)
        VOTHSG ~ add3_1.u1,                  # connect(VOTHSG, add3_1.u1)
        VUEL ~ add3_1.u3,                    # connect(VUEL, add3_1.u3)
        VR1.y ~ add.u2,                      # connect(VR1.y, add.u2)
        Gain1.y ~ add.u1,                    # connect(Gain1.y, add.u1)
        limiter.y ~ VA.u,                    # connect(limiter.y, VA.u)
        VA.y ~ add1.u2,                      # connect(VA.y, add1.u2)
        add1.y ~ Gain2.u,                    # connect(add1.y, Gain2.u)
        VM1.u ~ Gain2.u,                     # connect(VM1.u, Gain2.u)
        Gain2.y ~ add2.u1,                   # connect(Gain2.y, add2.u1)
        VM1.y ~ add2.u2,                     # connect(VM1.y, add2.u2)
        add2.y ~ limiter1.u,                 # connect(add2.y, limiter1.u)
        product.y ~ EFD,                     # connect(product.y, EFD)
        lV_Gate.u2 ~ VOEL,                   # connect(lV_Gate.u2, VOEL)
        limiter1.y ~ lV_Gate.u1,             # connect(limiter1.y, lV_Gate.u1)
        gain.u ~ EFD,                        # connect(gain.u, EFD)
        gain.y ~ add1.u1,                    # connect(gain.y, add1.u1)
        rcv.EFD ~ maxLimiter.u,              # connect(rectifierCommutationVoltageDrop.EFD, maxLimiter.u)
        VE ~ rcv.V_EX,                       # connect(VE, rectifierCommutationVoltageDrop.V_EX)
        connect(Gen_terminal, Bus),
        XADIFD ~ rcv.XADIFD,                 # connect(XADIFD, rectifierCommutationVoltageDrop.XADIFD)
    ]
    # VB0 = VE0*FEX(IN0), the .mo's if chain on the initialization unknown IN0 (both branches of an ifelse are
    # evaluated: the square root is guarded, inert on the selected branch)
    VB0_eq = ifelse(IN0 <= 0, VE0 * 1,
        ifelse((IN0 > 0) & (IN0 <= 0.433), VE0 * (1 - 0.577 * IN0),
            ifelse((IN0 > 0.433) & (IN0 < 0.75), VE0 * sqrt(max(0.75 - IN0^2, 0)),
                ifelse((IN0 >= 0.75) & (IN0 <= 1), VE0 * 1.732 * (1 - IN0), VE0 * 0))))
    extend(System(eqs, t, vars, pars; name, systems,
            initial_conditions = Dict(Ifd0 => missing, IN0 => missing, VB0 => missing, VA0 => missing, VR0 => missing, VE0 => missing),
            initialization_eqs = [Ifd0 ~ XADIFD, VE0 ~ VE, IN0 ~ K_C * Ifd0 / VE0, VB0 ~ VB0_eq, VA0 ~ Efd0 / VB0,
                VR0 ~ Efd0 * K_G, V_REF ~ ECOMP]), base)
end
