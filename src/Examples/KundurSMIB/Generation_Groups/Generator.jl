# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/KundurSMIB/Generation_Groups/Generator.mo (extends Interfaces/Generator.mo),
# transcribed automatically (2026-09-16); reviewed by hand.
# Named `KundurSMIB_Generator` (JULIA_NAMES): the leaf name collides with `Interfaces.Generator`.
# The Order6 machine alone, with vf <- vf0 and pm <- pm0 (no AVR, no governor). `Taa = 0`, so the .mo's
# `Taa/T1d0` terms vanish. Omitted: graphical annotations, displayPF.
@component function KundurSMIB_Generator(; name, S_b = 2220e6, V_b = 400e3, fn = 60, P_0 = 1e6, Q_0 = 0, v_0 = 1,
        angle_0 = 0, mods = (;))
    @named base = Generator(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    @unpack pwPin = base
    machine = redeclared(mods, :machine, Order6)(; name = :machine,
        modified(mods, :machine, (; Vn = 400000.0, V_b, ra = 0.003, xd = 1.81, xq = 1.76, x1d = 0.3, x1q = 0.65,
            x2d = 0.23, x2q = 0.25, T1d0 = 8.0, T1q0 = 1.0, T2d0 = 0.03, T2q0 = 0.07, M = 7.0, D = 0.0,
            P_0, Q_0, v_0, angle_0, Sn = 2220000000.0, Taa = 0.0, S_b, fn))...)
    eqs = Equation[
        machine.pm ~ machine.pm0,   # connect(machine.pm0, machine.pm)
        machine.vf ~ machine.vf0,   # connect(machine.vf0, machine.vf)
        connect(machine.p, pwPin),
    ]
    extend(System(eqs, t, [], []; name, systems = [machine]), base)
end
