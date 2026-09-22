# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Wind/PSSE/WT3G/WT3G1.mo (extends Electrical/Essentials/pfComponent.mo with every
# enable* at its default): the type-3 (DFIG) generator/converter.
# Blocks, with the names of the .mo: imIntegrator = Continuous.Integrator(k = wbase, y_start = angle_0,
# InitialOutput) - the PLL angle; imIntegrator1 = Continuous.LimIntegrator(outMin = -P_llmax, outMax = P_llmax,
# y_start = 0, InitialOutput, k = K_ipll); imSimpleLag = NonElectrical.Continuous.SimpleLag(K = 1, T = 0.02,
# y_start = Eqcmd0); imSimpleLag1 = SimpleLag(K = 1, T = 0.02, y_start = Ix0); imGain = Math.Gain(k = -1/X_eq);
# imGain1 = Math.Gain(k = K_pll/wbase); add = Math.Add; imLimited = Nonlinear.Limiter(uMin = -P_llmax,
# uMax = P_llmax).
# Ports are plain variables: the inputs Eqcmd, Ipcmd and the protected Vy; the outputs Iy, Ix, Iterm, delta, V, P,
# Q and the two parameter-valued ipcmd0, eqcmd0; plus the pin `p`.
# `Complex Is` is the pair `Is_re`, `Is_im` (PLAN-02, as in WT4G1.jl; the OpenModelica columns `Is.re`/`Is.im` are
# renamed in the Test). The matrix `[Ix; Iy] = -[cos d, sin d; -sin d, cos d]*[Is.re; Is.im]` is written as it
# stands, because here `Is.re`/`Is.im` are the ones given explicitly by the pin currents and `Ix`/`Iy` are the
# outputs; `[VX; VY] = [cos d, sin d; -sin d, cos d]*[p.vr; p.vi]` likewise. `atan2` is `atan(y, x)`.
# `V = VT` and `ipcmd0 = Ipcmd0`, `eqcmd0 = Eqcmd0` are binding equations of RealOutputs.
# Note `M_b = 100` in the .mo, i.e. 100 VA and a change of base of 1e-6 (sic): the default is kept.
# Omitted: `Complex Zs(re = 0, im = X_eq)` (declared and never used), displayPF, graphical annotations.

@component function WT3G1(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        X_eq, K_pll, K_ipll, P_llmax, P_rated, M_b = 100)
    S_b, V_b, fn, P_0, Q_0, v_0, angle_0, M_b = float.((S_b, V_b, fn, P_0, Q_0, v_0, angle_0, M_b))
    X_eq, K_pll, K_ipll, P_llmax, P_rated = float.((X_eq, K_pll, K_ipll, P_llmax, P_rated))
    # the protected parameters of the .mo, in its own order (plain Julia arithmetic, F-22)
    wbase = 2 * pi * fn
    p0 = P_0 / M_b
    q0 = Q_0 / M_b
    vr0 = v_0 * cos(angle_0)
    vi0 = v_0 * sin(angle_0)
    ir0 = (p0 * vr0 + q0 * vi0) / (vr0^2 + vi0^2)
    ii0 = (p0 * vi0 - q0 * vr0) / (vr0^2 + vi0^2)
    Isr0 = ir0 + vi0 / X_eq
    Isi0 = ii0 - vr0 / X_eq
    CoB = M_b / S_b
    ir1 = -CoB * ir0
    ii1 = -CoB * ii0
    Ix0 = Isr0 * cos(-angle_0) - Isi0 * sin(-angle_0)
    Iy0 = Isr0 * sin(-angle_0) + cos(-angle_0) * Isi0
    Eqcmd0 = -Iy0 * X_eq
    Ipcmd0 = Ix0
    VX0 = cos(angle_0) * vr0 + sin(angle_0) * vi0
    VY0 = (-sin(angle_0) * vr0) + cos(angle_0) * vi0
    base = pfComponent(; name, S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    systems = @named begin
        p = PwPin()
        imIntegrator = Integrator(; k = wbase, y_start = angle_0, initType = :InitialOutput)
        imIntegrator1 = LimIntegrator(; outMin = -P_llmax, outMax = P_llmax, y_start = 0,
            initType = :InitialOutput, k = K_ipll)
        imSimpleLag = SimpleLag(; K = 1, T = 0.02, y_start = Eqcmd0)
        imSimpleLag1 = SimpleLag(; K = 1, T = 0.02, y_start = Ix0)
        imGain = Gain(; k = -1 / X_eq)
        imGain1 = Gain(; k = K_pll / wbase)
        add = Add()
        imLimited = Limiter(; uMin = -P_llmax, uMax = P_llmax)
    end
    pars = @parameters begin
        X_eq = X_eq, [description = "Equivalent reactance for current injection (pu)"]
        K_pll = K_pll, [description = "PLL first integrator gain (pu)"]
        K_ipll = K_ipll, [description = "PLL second integrator gain"]
        P_llmax = P_llmax, [description = "PLL maximum limit (pu)"]
        P_rated = P_rated, [description = "Turbine rating, not used in the equation (W)"]
        M_b = M_b, [description = "Machine base power (VA)"]
        wbase = wbase, [description = "System base speed (rad/s)"]
        p0 = p0
        q0 = q0
        vr0 = vr0
        vi0 = vi0
        ir0 = ir0
        ii0 = ii0
        Isr0 = Isr0
        Isi0 = Isi0
        CoB = CoB
        ir1 = ir1
        ii1 = ii1
        Ix0 = Ix0
        Iy0 = Iy0
        Eqcmd0 = Eqcmd0
        Ipcmd0 = Ipcmd0
        VX0 = VX0
        VY0 = VY0
    end
    vars = @variables begin
        VT(t), [description = "Bus voltage magnitude"]
        anglev(t), [description = "Bus voltage angle"]
        VY(t), [description = "y-axis terminal voltage"]
        VX(t), [description = "x-axis terminal voltage"]
        Is_re(t), [description = "Equivalent internal current source, real part (Is.re)"]
        Is_im(t), [description = "Equivalent internal current source, imaginary part (Is.im)"]
        Iy(t)
        Ix(t)
        Iterm(t)
        Eqcmd(t)
        Ipcmd(t)
        delta(t)
        V(t)
        P(t), [description = "On machine base"]
        Q(t)
        ipcmd0(t)
        eqcmd0(t)
        Vy(t)
    end
    eqs = Equation[
        V ~ VT,                                     # RealOutput V = VT
        ipcmd0 ~ Ipcmd0,                            # RealOutput ipcmd0 = Ipcmd0
        eqcmd0 ~ Eqcmd0,                            # RealOutput eqcmd0 = Eqcmd0
        anglev ~ atan(p.vi, p.vr),                  # atan2(p.vi, p.vr)
        VT ~ sqrt(p.vr * p.vr + p.vi * p.vi),
        Iterm ~ sqrt(p.ir * p.ir + p.ii * p.ii),
        Is_re ~ p.ir / CoB - p.vi / X_eq,
        # the positive direction for p.ir is the antidirection of ir0
        Is_im ~ p.ii / CoB + p.vr / X_eq,
        Vy ~ VY,
        Ix ~ -(cos(delta) * Is_re + sin(delta) * Is_im),     # [Ix; Iy] = -[cos d, sin d; -sin d, cos d]*[Is.re; Is.im]
        Iy ~ -((-sin(delta)) * Is_re + cos(delta) * Is_im),
        VX ~ cos(delta) * p.vr + sin(delta) * p.vi,          # [VX; VY] = [cos d, sin d; -sin d, cos d]*[p.vr; p.vi]
        VY ~ (-sin(delta)) * p.vr + cos(delta) * p.vi,
        -P ~ p.vr * p.ir / CoB + p.vi * p.ii / CoB,
        -Q ~ p.vi * p.ir / CoB - p.vr * p.ii / CoB,
        imSimpleLag.u ~ Eqcmd,                      # connect(Eqcmd, imSimpleLag.u)
        imSimpleLag1.u ~ Ipcmd,                     # connect(Ipcmd, imSimpleLag1.u)
        imLimited.u ~ add.y,                        # connect(add.y, imLimited.u)
        imIntegrator.u ~ imLimited.y,               # connect(imLimited.y, imIntegrator.u)
        delta ~ imIntegrator.y,                     # connect(imIntegrator.y, delta)
        imGain1.u ~ Vy,                             # connect(Vy, imGain1.u)
        imGain.u ~ imSimpleLag.y,                   # connect(imSimpleLag.y, imGain.u)
        Iy ~ imGain.y,                              # connect(imGain.y, Iy)
        Ix ~ imSimpleLag1.y,                        # connect(imSimpleLag1.y, Ix)
        add.u2 ~ imGain1.y,                         # connect(imGain1.y, add.u2)
        imIntegrator1.u ~ add.u2,                   # connect(imIntegrator1.u, add.u2)
        add.u1 ~ imIntegrator1.y,                   # connect(imIntegrator1.y, add.u1)
    ]
    guesses = Dict(p.vr => vr0, p.vi => vi0, p.ir => ir1, p.ii => ii1, VT => v_0, anglev => angle_0,
        VY => VY0, VX => VX0, delta => angle_0, Ix => Ix0, Iy => Iy0, Iterm => sqrt(ir1^2 + ii1^2),
        Eqcmd => Eqcmd0, Ipcmd => Ipcmd0, Is_re => Isr0, Is_im => Isi0, P => p0, Q => q0)
    extend(System(eqs, t, vars, pars; name, systems, guesses), base)
end
