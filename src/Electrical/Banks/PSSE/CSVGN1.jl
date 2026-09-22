# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Banks/PSSE/CSVGN1.mo (extends nothing; `outer SystemBase SysData` -> the S_b keyword)
# Static shunt compensator. It declares its own power-flow parameters instead of extending pfComponent, and it has no
# fn. Blocks as subsystems with the .mo's instance names (`const` is a Julia keyword, so the instance is `const_`, as
# in SimpleLagLim); every block takes numbers, computed before `@parameters` (F-22), except `const2 = Constant(k =
# Vref)`, which takes the symbolic parameter.
# `Vref(fixed = false)` is resolved by `initial equation Vref = V - k0` from the INPUT V (the terminal voltage at
# t = 0), not from other parameters: it is declared with a `guess`, listed as `missing` in `initial_conditions` and
# given its equation in `initialization_eqs` (F-33). `k50`, `k30` and `k0` are also `fixed = false` but depend on
# parameters alone, so Julia computes them. The rotation by the constant delta0 and `vq = id/Y`, `vd = -iq/Y` are
# literal. Omitted: Icons.VerifiedModel, graphical annotations.

@component function CSVGN1(; name, S_b = 100e6, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0, ra = 0, x1d = 9999,
        K = 1, T1 = 0, T2 = 0, T3 = 0, T4 = 0, T5 = 0, RMIN = 0, VMAX = 0.5, VMIN = 0, CBASE = 100e6, MBASE = 100e6)
    S_b, P_0, Q_0, v_0, angle_0, ra, x1d, K, T1, T2, T3, T4, T5, RMIN, VMAX, VMIN, CBASE, MBASE =
        float.((S_b, P_0, Q_0, v_0, angle_0, ra, x1d, K, T1, T2, T3, T4, T5, RMIN, VMAX, VMIN, CBASE, MBASE))  # F-21
    p0 = P_0 / S_b
    q0 = Q_0 / S_b
    Y0 = q0 / (v_0 * v_0)
    vr0 = v_0 * cos(angle_0)
    vi0 = v_0 * sin(angle_0)
    ir0 = (p0 * vr0 + q0 * vi0) / (vr0^2 + vi0^2)
    ii0 = (p0 * vi0 - q0 * vr0) / (vr0^2 + vi0^2)
    delta0 = atan(vi0 + ra * ii0 + x1d * ir0, vr0 + ra * ir0 - x1d * ii0)   # atan2
    vd0 = vr0 * cos(pi / 2 - delta0) - vi0 * sin(pi / 2 - delta0)
    vq0 = vr0 * sin(pi / 2 - delta0) + vi0 * cos(pi / 2 - delta0)
    id0 = ir0 * cos(pi / 2 - delta0) - ii0 * sin(pi / 2 - delta0)
    iq0 = ir0 * sin(pi / 2 - delta0) + ii0 * cos(pi / 2 - delta0)
    # `initial equation k50 = ...; k30 = k50; k0 = k30/K` involves parameters only, so it is solved here
    k50 = (CBASE / S_b - Y0) / (MBASE / S_b)
    k30 = k50
    k0 = k30 / K
    eps = Modelica.Constants.eps
    # numeric copies of every modifier the sub-blocks take: `@parameters` below rebinds these names to symbols (F-22)
    n = (K = K, MBoS = MBASE / S_b, CBoS = CBASE / S_b, outMin = RMIN / MBASE, T5 = T5, VMAX = VMAX, VMIN = VMIN,
        llT1 = T1 + eps, llT2 = T3 + eps, lllT1 = T2 + eps, lllT2 = T4 + eps, k50 = k50, k30 = k30)
    pars = @parameters begin
        S_b = S_b, [description = "System base power (VA)"]
        P_0 = P_0, [description = "Initial active power (W)"]
        Q_0 = Q_0, [description = "Initial reactive power (var)"]
        v_0 = v_0, [description = "Initial voltage magnitude at terminal bus (pu)"]
        angle_0 = angle_0, [description = "Initial voltage angle (rad)"]
        ra = ra, [description = "Armature resistance (pu)"]
        x1d = x1d, [description = "d-axis transient reactance, should be set to 9999 (pu)"]
        K = K
        T1 = T1
        T2 = T2
        T3 = T3
        T4 = T4
        T5 = T5
        RMIN = RMIN, [description = "Reactor minimum var output (var)"]
        VMAX = VMAX
        VMIN = VMIN
        CBASE = CBASE, [description = "Capacitor output (var)"]
        MBASE = MBASE, [description = "Power range of SVC (VA)"]
        p0 = p0, [description = "Active power (system base, pu)"]
        q0 = q0, [description = "Reactive power (system base, pu)"]
        Y0 = Y0, [description = "Capacitor output (pu)"]
        vr0 = vr0
        vi0 = vi0
        ir0 = ir0
        ii0 = ii0
        delta0 = delta0
        vd0 = vd0
        vq0 = vq0
        id0 = id0
        iq0 = iq0
        k50 = k50
        k30 = k30
        k0 = k0
        Vref, [guess = v_0 - k0]   # fixed = false: resolved from the input V by the initial equation below
    end
    systems = @named begin
        product1 = Product()
        add = Add(; k2 = -1)
        add1 = Add(; k1 = -1)
        const_ = Constant(; k = n.MBoS)   # `const` in the .mo
        const1 = Constant(; k = n.CBoS)
        LagLim = SimpleLagLim(; outMin = n.outMin, outMax = 1.0, T = n.T5, K = 1.0, y_start = n.k50)
        const2 = Constant(; k = Vref)
        p = PwPin()
        leadLag = LeadLag(; K = n.K, T1 = n.llT1, T2 = n.llT2, y_start = n.k30)
        leadLagLim = LeadLagLim(; K = n.K, T1 = n.lllT1, T2 = n.lllT2, outMax = n.VMAX, outMin = n.VMIN, y_start = n.k30)
        add2 = Add(; k2 = -1)
    end
    vars = @variables begin
        v(t), [description = "Bus voltage magnitude (pu)"]
        anglev(t), [description = "Bus voltage angle (rad)"]
        P(t)
        Q(t)
        vd(t), [description = "voltage direct axis"]
        vq(t), [description = "voltage quadrature axis"]
        id(t), [description = "current direct axis"]
        iq(t), [description = "current quadrature axis"]
        Y(t), [description = "Susceptance output"]
        V(t), [description = "Terminal voltage input"]
        VOTHSG(t), [description = "Other signal input"]
    end
    eqs = Equation[
        v ~ sqrt(p.vr^2 + p.vi^2),
        anglev ~ atan(p.vi, p.vr),   # atan2(p.vi, p.vr)
        p.ir ~ -(sin(delta0) * id + cos(delta0) * iq),
        p.ii ~ -(-cos(delta0) * id + sin(delta0) * iq),
        p.vr ~ sin(delta0) * vd + cos(delta0) * vq,
        p.vi ~ -cos(delta0) * vd + sin(delta0) * vq,
        vq ~ id / Y,
        vd ~ -iq / Y,
        -P ~ p.vr * p.ir + p.vi * p.ii,
        -Q ~ p.vi * p.ir - p.vr * p.ii,
        const1.y ~ add.u1,       # connect(const1.y, add.u1)
        add.y ~ Y,               # connect(add.y, Y)
        product1.y ~ add.u2,     # connect(product1.y, add.u2)
        V ~ add1.u2,             # connect(V, add1.u2)
        const_.y ~ product1.u1,  # connect(const.y, product1.u1)
        leadLag.y ~ leadLagLim.u,
        leadLagLim.y ~ LagLim.u,
        LagLim.y ~ product1.u2,
        VOTHSG ~ add2.u2,        # connect(VOTHSG, add2.u2)
        add1.y ~ add2.u1,
        add2.y ~ leadLag.u,
        const2.y ~ add1.u1,
    ]
    System(eqs, t, vars, pars; name, systems,
        initial_conditions = Dict(Vref => missing),
        initialization_eqs = [Vref ~ V - k0],
        guesses = Dict(v => v_0, anglev => angle_0, vd => vd0, vq => vq0, id => id0, iq => iq0, Y => Y0,
            p.vr => vr0, p.vi => vi0, p.ir => ir0, p.ii => ii0))
end
