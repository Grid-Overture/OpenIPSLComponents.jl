# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Renewables/PSSE/InverterInterface/REGCA1.mo (extends BaseClasses/BaseREGC.mo)
# Blocks, with the .mo's own names: Vt = RealExpression(VT), add(k2 = -1), Vo_limit = Constant(Volim),
# KHV = Gain(Khv), min_limiter = Limiter(inf, 0), add1(k2 = -1), IOLIM = Limiter(inf, Iolim), gain = Gain(-1),
# add3(k2 = -1), limiter1(Iqrmax, Iqrmin), integrator = Integrator(1/Tg, InitialState, Iq0), add2(k2 = -1),
# limiter4(rrpwr, -inf), integrator1 = Integrator(1/Tg, InitialState, Ip0), variableLimiter, LowerLimit =
# RealExpression(-inf), Constant = RealExpression(+inf) (an instance called exactly like the block `Constant`,
# which it shadows inside the function: `Vo_limit` therefore reaches the block through the qualified call
# `OpenIPSLComponents.Constant`, F-61), switch1 = Switch + Lvplsw_logic = BooleanConstant(Lvplsw) (both instantiated
# literally; `mtkcompile` reduces them, precedent TGTypeVI), LVPL(Brkpt, Lvpl1, Zerox) over
# simpleLag = SimpleLag(K = 1, T = Tfltr, y_start = v_0), LVACM(lvpnt0, lvpnt1) over
# Terminal_Voltage1 = RealExpression(Vt.y), IP = Product.
# `Modelica.Constants.inf` is **1e60** in this package (OpenModelica's ModelicaServices.Machine), not `Inf`: no
# infinite limit ever reaches an `ifelse` as `Inf`.
# The matrix equation `[IP.y; IOLIM.y] = -R(delta)*[p.ir/CoB; p.ii/CoB]` is written as its two rows **solved by the
# inverse rotation**, `p.ir = -CoB*(cos(delta)*IP.y - sin(delta)*IOLIM.y)` and
# `p.ii = -CoB*(sin(delta)*IP.y + cos(delta)*IOLIM.y)`: the pin currents become explicit without changing the
# relation (the same solution for every delta, R being orthogonal). This is the matrix inverted by hand, not a
# deviation of form like F-16.
# `Lvplsw` is a Boolean parameter and `switch1`'s branch is therefore fixed at translation time; it is nevertheless
# instantiated as MSL's `Switch` with a `BooleanConstant`, because the OpenModelica CSV carries those columns.
# Omitted: Icons.VerifiedModel, graphical annotations.

@component function REGCA1(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        M_b = nothing, Tg = 0.02, rrpwr = 10, Brkpt = 0.9, Zerox = 0.5, Lvpl1 = 1.22, Volim = 1.2,
        lvpnt1 = 0.8, lvpnt0 = 0.4, Iolim = -1.3, Tfltr = 0.02, Khv = 0.7, Iqrmax = 9999, Iqrmin = -9999,
        Lvplsw = true)
    S_b, V_b, fn, P_0, Q_0, v_0, angle_0 = float.((S_b, V_b, fn, P_0, Q_0, v_0, angle_0))
    M_bn = M_b === nothing ? S_b : float(M_b)
    n = regc_init(P_0, Q_0, v_0, angle_0, M_bn, S_b)     # numeric Ip0 / Iq0 for the two integrators (F-22)
    nb = float.((Tg, rrpwr, Brkpt, Zerox, Lvpl1, Volim, lvpnt1, lvpnt0, Iolim, Tfltr, Khv, Iqrmax, Iqrmin))
    Tgn, rrpwrn, Brkptn, Zeroxn, Lvpl1n, Volimn, lvpnt1n, lvpnt0n, Iolimn, Tfltrn, Khvn, Iqrmaxn, Iqrminn = nb
    inf = Modelica.Constants.inf
    base = BaseREGC(; name, S_b, V_b, fn, P_0, Q_0, v_0, angle_0, M_b, Tg, rrpwr, Brkpt, Zerox, Lvpl1, Volim,
        lvpnt1, lvpnt0, Iolim, Tfltr, Khv, Iqrmax, Iqrmin)
    @unpack p, Iqcmd, Ipcmd, IQ0, IP0, V_0, q_0, p_0, V_t, Pgen, Qgen, delta, VT = base
    systems = @named begin
        Vt = RealExpression(; expr = nothing)      # y = VT, a parent variable: the equation is written below (F-22)
        add = Add(; k2 = -1)
        Vo_limit = OpenIPSLComponents.Constant(; k = Volimn)
        min_limiter = Limiter(; uMax = inf, uMin = 0.0)
        add1 = Add(; k2 = -1)
        IOLIM = Limiter(; uMax = inf, uMin = Iolimn)
        LVACM = OpenIPSLComponents.LVACM(; lvpnt0 = lvpnt0n, lvpnt1 = lvpnt1n)
        simpleLag = SimpleLag(; K = 1, T = Tfltrn, y_start = v_0)
        LVPL = OpenIPSLComponents.LVPL(; Brkpt = Brkptn, Lvpl1 = Lvpl1n, Zerox = Zeroxn)
        IP = Product()
        KHV = Gain(; k = Khvn)
        Lvplsw_logic = BooleanConstant(; k = Lvplsw)
        limiter4 = Limiter(; uMax = rrpwrn, uMin = -inf)
        add2 = Add(; k2 = -1)
        Terminal_Voltage1 = RealExpression(; expr = nothing)   # y = Vt.y, written below (F-22)
        LowerLimit = RealExpression(; expr = -inf)
        add3 = Add(; k2 = -1)
        limiter1 = Limiter(; uMax = Iqrmaxn, uMin = Iqrminn)
        integrator = Integrator(; k = 1 / Tgn, initType = :InitialState, y_start = n.Iq0)
        gain = Gain(; k = -1)
        Constant = RealExpression(; expr = inf)
        integrator1 = Integrator(; k = 1 / Tgn, initType = :InitialState, y_start = n.Ip0)
        switch1 = Switch()
        variableLimiter = VariableLimiter()
    end
    eqs = Equation[
        Vt.y ~ VT,                           # RealExpression Vt(y = VT)
        Terminal_Voltage1.y ~ Vt.y,          # RealExpression Terminal_Voltage1(y = Vt.y)
        # [IP.y; IOLIM.y] = -[cos(delta), sin(delta); -sin(delta), cos(delta)]*[p.ir/CoB; p.ii/CoB], solved for the
        # pin currents by the inverse rotation (see the header)
        p.ir ~ -n.CoB * (cos(delta) * IP.y - sin(delta) * IOLIM.y),
        p.ii ~ -n.CoB * (sin(delta) * IP.y + cos(delta) * IOLIM.y),
        V_t ~ VT,
        Pgen ~ -(1 / n.CoB) * (p.vr * p.ir + p.vi * p.ii),
        Qgen ~ -(1 / n.CoB) * (p.vi * p.ir - p.vr * p.ii),
        IQ0 ~ n.Iq0,
        IP0 ~ n.Ip0,
        V_0 ~ v_0,
        p_0 ~ n.p0,
        q_0 ~ n.q0,
        add.y ~ KHV.u,                       # connect(add.y, KHV.u)
        LVPL.V ~ simpleLag.y,                # connect(LVPL.V, simpleLag.y)
        LVACM.y ~ IP.u2,                     # connect(LVACM.y, IP.u2)
        switch1.u1 ~ LVPL.y,                 # connect(switch1.u1, LVPL.y)
        Lvplsw_logic.y ~ switch1.u2,         # connect(Lvplsw_logic.y, switch1.u2)
        KHV.y ~ min_limiter.u,               # connect(KHV.y, min_limiter.u)
        Vt.y ~ add.u1,                       # connect(Vt.y, add.u1)
        simpleLag.u ~ LVACM.Vt,              # connect(simpleLag.u, LVACM.Vt)
        Vo_limit.y ~ add.u2,                 # connect(Vo_limit.y, add.u2)
        add2.y ~ limiter4.u,                 # connect(add2.y, limiter4.u)
        Terminal_Voltage1.y ~ LVACM.Vt,      # connect(Terminal_Voltage1.y, LVACM.Vt)
        add3.y ~ limiter1.u,                 # connect(add3.y, limiter1.u)
        limiter1.y ~ integrator.u,           # connect(limiter1.y, integrator.u)
        integrator.y ~ add3.u2,              # connect(integrator.y, add3.u2)
        gain.y ~ add3.u1,                    # connect(gain.y, add3.u1)
        gain.u ~ Iqcmd,                      # connect(gain.u, Iqcmd)
        Ipcmd ~ add2.u1,                     # connect(Ipcmd, add2.u1)
        Constant.y ~ switch1.u3,             # connect(Constant.y, switch1.u3)
        limiter4.y ~ integrator1.u,          # connect(limiter4.y, integrator1.u)
        LowerLimit.y ~ variableLimiter.limit2,   # connect(LowerLimit.y, variableLimiter.limit2)
        integrator1.y ~ variableLimiter.u,   # connect(integrator1.y, variableLimiter.u)
        variableLimiter.limit1 ~ switch1.y,  # connect(variableLimiter.limit1, switch1.y)
        variableLimiter.y ~ add2.u2,         # connect(variableLimiter.y, add2.u2)
        IP.u1 ~ add2.u2,                     # connect(IP.u1, add2.u2)
        add1.y ~ IOLIM.u,                    # connect(add1.y, IOLIM.u)
        add1.u1 ~ integrator.y,              # connect(add1.u1, integrator.y)
        min_limiter.y ~ add1.u2,             # connect(min_limiter.y, add1.u2)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end
