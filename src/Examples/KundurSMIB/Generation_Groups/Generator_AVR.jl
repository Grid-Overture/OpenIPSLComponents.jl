# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/KundurSMIB/Generation_Groups/Generator_AVR.mo (extends Interfaces/Generator.mo),
# transcribed automatically (2026-09-16); reviewed by hand. Named `KundurSMIB_Generator_AVR`.
# Order6 + AVRtypeIII + a `pss_off` constant on the stabilizer input. `machine(w(fixed = true))` is already the
# initial condition of baseMachine (F-20); `SMIB_AVR` adds `machine(delta(fixed = true))`, also already there, so
# `mods` exists only to let a system pass a modifier that is not one of those two.
# `T1 = T2 = 1` cancels the `1 - T1/T2` term of AVRtypeIII, which leaves vr a decay from 0 (header of AVRtypeIII.jl).
# Omitted: graphical annotations, displayPF.
@component function KundurSMIB_Generator_AVR(; name, S_b = 2220e6, V_b = 400e3, fn = 60, P_0 = 1e6, Q_0 = 0, v_0 = 1,
        angle_0 = 0, mods = (;))
    @named base = Generator(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    @unpack pwPin = base
    machine = redeclared(mods, :machine, Order6)(; name = :machine,
        modified(mods, :machine, (; Vn = 400000.0, V_b, ra = 0.003, xd = 1.81, xq = 1.76, x1d = 0.3, x1q = 0.65,
            x2d = 0.23, x2q = 0.25, T1d0 = 8.0, T1q0 = 1.0, T2d0 = 0.03, T2q0 = 0.07, M = 7.0, D = 0.0,
            P_0, Q_0, v_0, angle_0, Sn = 2220000000.0, Taa = 0.0, S_b, fn))...)
    systems = @named begin
        avr = AVRtypeIII(; vfmax = 7.0, vfmin = -6.40, K0 = 200.0, T2 = 1.0, T1 = 1.0, Te = 0.0001, Tr = 0.015)
        pss_off = Constant(; k = 0.0)
    end
    eqs = Equation[
        machine.pm ~ machine.pm0,   # connect(machine.pm0, machine.pm)
        connect(machine.p, pwPin),
        avr.vs ~ pss_off.y,         # connect(pss_off.y, avr.vs)
        machine.vf ~ avr.vf,        # connect(avr.vf, machine.vf)
        avr.v ~ machine.v,          # connect(machine.v, avr.v)
        avr.vf0 ~ machine.vf0,      # connect(machine.vf0, avr.vf0)
    ]
    extend(System(eqs, t, [], []; name, systems = [machine; systems]), base)
end
