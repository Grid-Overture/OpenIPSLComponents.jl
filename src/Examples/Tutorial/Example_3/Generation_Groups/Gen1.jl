# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/Tutorial/Example_3/Generation_Groups/Gen1.mo, drafted automatically
# (2026-09-14, --kind base); reviewed by hand. extends: OpenIPSL.Interfaces.Generator.
# 100 MVA / 18 kV unit of bus 1: an Order4 machine, an AVRTypeII and the voltage-reference disturbance path
# (step -> switch1, enabled by booleanConstant(k = refdisturb)). `height`, `tstart` and `refdisturb` have no default
# in the .mo and are required keyword arguments; `vf0` and `vref0` keep theirs and are inert with refdisturb = false
# (F-05), `vref0` only as the step's offset. The .mo redeclares `pwPin` identically to Generator's, so the Julia
# child takes the inherited one with `@unpack`. Gen2.jl and Gen3.jl extend this file through `mods`.
# Omitted: displayPF, graphical annotations.

@component function Gen1(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        vf0 = 1.755517086537914, vref0 = 1.118023800520641, height, tstart, refdisturb, mods = (;))
    @named base = Generator(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    @unpack pwPin = base
    gen = redeclared(mods, :gen, Order4)(; name = :gen, modified(mods, :gen, (; Sn = 100000000.0, Vn = 18000.0,
        V_b = V_b, v_0 = v_0, angle_0 = angle_0, P_0 = P_0, Q_0 = Q_0, ra = 0.0, xd = 0.8958, xq = 0.8645,
        x1d = 0.1198, x1q = 0.1969, T1d0 = 6.0, T1q0 = 0.5350, M = 12.8, D = 0.0, S_b, fn))...)
    AVR = redeclared(mods, :AVR, AVRTypeII)(; name = :AVR, modified(mods, :AVR, (; vrmin = -5.0, vrmax = 5.0,
        v0 = v_0, Ka = 20.0, Ta = 0.2, Kf = 0.063, Tf = 0.35, Ke = 1.0, Te = 0.314, Tr = 0.001, Ae = 0.0039,
        Be = 1.555))...)
    step = redeclared(mods, :step, Step)(; name = :step,
        modified(mods, :step, (; startTime = tstart, offset = vref0, height = height))...)
    switch1 = redeclared(mods, :switch1, Switch)(; name = :switch1, modified(mods, :switch1, (;))...)
    booleanConstant = redeclared(mods, :booleanConstant, BooleanConstant)(; name = :booleanConstant,
        modified(mods, :booleanConstant, (; k = refdisturb))...)
    systems = [gen, AVR, step, switch1, booleanConstant]
    eqs = Equation[
        gen.v ~ AVR.v,              # connect(gen.v, AVR.v)
        switch1.y ~ AVR.vref,       # connect(switch1.y, AVR.vref)
        booleanConstant.y ~ switch1.u2,   # connect(booleanConstant.y, switch1.u2)
        step.y ~ switch1.u1,        # connect(step.y, switch1.u1)
        connect(gen.p, pwPin),
        AVR.vf ~ gen.vf,            # connect(AVR.vf, gen.vf)
        gen.pm0 ~ gen.pm,           # connect(gen.pm0, gen.pm)
        gen.vf0 ~ AVR.vf0,          # connect(gen.vf0, AVR.vf0)
        AVR.vref0 ~ switch1.u3,     # connect(AVR.vref0, switch1.u3)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end
