# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/IEEE9/Generation_Groups/Gen1.mo (extends Electrical/Essentials/pfComponent.mo),
# drafted automatically (2026-09-16, --kind base); reviewed by hand.
# Named `IEEE9_Gen1` (JULIA_NAMES): `Gen1` is the group of Examples.Tutorial.Example_3 (batch 0).
# 18 kV / 100 MVA unit of bus 2 (the .mo's own comment): an Order4 machine, an AVRTypeII and the voltage-reference disturbance path
# (step -> switch1, enabled by booleanConstant(k = refdisturb_1)). Unlike Example_3's groups this one extends
# `pfComponent` and declares its own `pwPin`, and it carries the display variables P_MW, Q_Mvar (kept: they are
# equations of the .mo, not annotations). `height_1`, `tstart_1` and `refdisturb_1` have no default in the .mo and
# are required keyword arguments; `vf0` and `vref0` keep theirs and are inert with refdisturb = false (F-05),
# `vref0` only as the step's offset.
# `P_MW = gen.P*S_b` and `Q_Mvar = gen.Q*S_b` take the numeric S_b keyword argument: the base's symbol would have to
# be `@unpack`ed, and that rebinding would then reach Order4/AVRTypeII as a symbol (F-22, point 1).
# Omitted: displayPF, graphical annotations.

@component function IEEE9_Gen1(; name, S_b = 100e6, V_b = 400e3, fn = 60, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        vf0 = 1.755517086537914, vref0 = 1.118023800520641, height_1, tstart_1, refdisturb_1, mods = (;))
    @named base = pfComponent(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    gen = redeclared(mods, :gen, Order4)(; name = :gen, modified(mods, :gen, (; Sn = 100000000.0, Vn = 18000.0,
        V_b, v_0, angle_0, P_0, Q_0, ra = 0.0, xd = 0.8958, xq = 0.8645, x1d = 0.1198, x1q = 0.1969, T1d0 = 6.0,
        T1q0 = 0.5350, M = 12.8, D = 0.0, S_b, fn))...)
    AVR = redeclared(mods, :AVR, AVRTypeII)(; name = :AVR, modified(mods, :AVR, (; vrmin = -5.0, vrmax = 5.0,
        v0 = v_0, Ka = 20.0, Ta = 0.2, Kf = 0.063, Tf = 0.35, Ke = 1.0, Te = 0.314, Tr = 0.001, Ae = 0.0039,
        Be = 1.555))...)
    step = redeclared(mods, :step, Step)(; name = :step,
        modified(mods, :step, (; startTime = tstart_1, offset = vref0, height = height_1))...)
    switch1 = redeclared(mods, :switch1, Switch)(; name = :switch1, modified(mods, :switch1, (;))...)
    booleanConstant = redeclared(mods, :booleanConstant, BooleanConstant)(; name = :booleanConstant,
        modified(mods, :booleanConstant, (; k = refdisturb_1))...)
    pwPin_ = PwPin(; name = :pwPin)
    systems = [gen, AVR, step, switch1, booleanConstant, pwPin_]
    vars = @variables begin
        P_MW(t), [description = "For icon display"]
        Q_Mvar(t), [description = "For icon display"]
    end
    eqs = Equation[
        P_MW ~ gen.P * S_b,
        Q_Mvar ~ gen.Q * S_b,
        gen.v ~ AVR.v,                    # connect(gen.v, AVR.v)
        AVR.vref ~ switch1.y,             # connect(switch1.y, AVR.vref)
        switch1.u2 ~ booleanConstant.y,   # connect(booleanConstant.y, switch1.u2)
        switch1.u1 ~ step.y,              # connect(step.y, switch1.u1)
        connect(gen.p, pwPin_),
        gen.vf ~ AVR.vf,                  # connect(AVR.vf, gen.vf)
        gen.pm ~ gen.pm0,                 # connect(gen.pm0, gen.pm)
        AVR.vf0 ~ gen.vf0,                # connect(gen.vf0, AVR.vf0)
        switch1.u3 ~ AVR.vref0,           # connect(AVR.vref0, switch1.u3)
    ]
    extend(System(eqs, t, vars, []; name, systems), base)
end
