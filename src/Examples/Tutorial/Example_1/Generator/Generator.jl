# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/Tutorial/Example_1/Generator/Generator.mo (extends Interfaces/Generator.mo),
# transcribed automatically (2026-09-16); reviewed by hand.
# Named `Example_1_Generator` (JULIA_NAMES): the leaf name collides with `Interfaces.Generator`.
# Order6 of 2220 MVA (Taa = 0.002 here, unlike the KundurSMIB group's 0) + AVRtypeIII + a `pss_off` constant on the
# stabilizer input. T1 = T2 = 1 cancels AVRtypeIII's `1 - T1/T2` term (header of AVRtypeIII.jl).
# Omitted: graphical annotations, displayPF.
@component function Example_1_Generator(; name, S_b = 100e6, V_b = 400e3, fn = 60, P_0 = 1e6, Q_0 = 0, v_0 = 1,
        angle_0 = 0)
    @named base = Generator(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    @unpack pwPin = base
    systems = @named begin
        avr = AVRtypeIII(; vfmax = 7.0, vfmin = -6.40, K0 = 200.0, T2 = 1.0, T1 = 1.0, Te = 0.0001, Tr = 0.015)
        machine = Order6(; ra = 0.003, xd = 1.81, xq = 1.76, x1d = 0.3, x1q = 0.65, x2d = 0.23, x2q = 0.25,
            T1d0 = 8.0, T1q0 = 1.0, T2d0 = 0.03, T2q0 = 0.07, Taa = 0.002, M = 7.0, D = 0.0, Sn = 2220000000.0,
            V_b, v_0, angle_0, P_0, Q_0, Vn = 400000.0, S_b, fn)
        pss_off = Constant(; k = 0.0)
    end
    eqs = Equation[
        machine.vf ~ avr.vf,        # connect(avr.vf, machine.vf)
        avr.v ~ machine.v,          # connect(avr.v, machine.v)
        machine.pm ~ machine.pm0,   # connect(machine.pm0, machine.pm)
        avr.vs ~ pss_off.y,         # connect(pss_off.y, avr.vs)
        avr.vf0 ~ machine.vf0,      # connect(avr.vf0, machine.vf0)
        connect(machine.p, pwPin),
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end
