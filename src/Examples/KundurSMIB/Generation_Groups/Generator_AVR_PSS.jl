# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/KundurSMIB/Generation_Groups/Generator_AVR_PSS.mo (extends Interfaces/Generator.mo),
# transcribed automatically (2026-09-16); reviewed by hand. Named `KundurSMIB_Generator_AVR_PSS`.
# Order6 + AVRtypeIII + PSSTypeII (vSI <- machine.w, vs -> avr.vs). This is the numeric validation of PSSTypeII
# against OpenModelica (with Examples.Tutorial.Example_2), since its own model has no upstream Test.
# Omitted: graphical annotations, displayPF.
@component function KundurSMIB_Generator_AVR_PSS(; name, S_b = 2220e6, V_b = 400e3, fn = 60, P_0 = 1e6, Q_0 = 0,
        v_0 = 1, angle_0 = 0, mods = (;))
    @named base = Generator(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    @unpack pwPin = base
    machine = redeclared(mods, :machine, Order6)(; name = :machine,
        modified(mods, :machine, (; Vn = 400000.0, V_b, ra = 0.003, xd = 1.81, xq = 1.76, x1d = 0.3, x1q = 0.65,
            x2d = 0.23, x2q = 0.25, T1d0 = 8.0, T1q0 = 1.0, T2d0 = 0.03, T2q0 = 0.07, M = 7.0, D = 0.0,
            P_0, Q_0, v_0, angle_0, Sn = 2220000000.0, Taa = 0.0, S_b, fn))...)
    systems = @named begin
        avr = AVRtypeIII(; vfmax = 7.0, vfmin = -6.40, K0 = 200.0, T2 = 1.0, T1 = 1.0, Te = 0.0001, Tr = 0.015)
        pss = PSSTypeII(; vsmax = 0.2, vsmin = -0.2, Kw = 9.5, Tw = 1.41, T1 = 0.154, T2 = 0.033, T3 = 1.0, T4 = 1.0)
    end
    eqs = Equation[
        machine.pm ~ machine.pm0,   # connect(machine.pm0, machine.pm)
        connect(machine.p, pwPin),
        machine.vf ~ avr.vf,        # connect(avr.vf, machine.vf)
        avr.v ~ machine.v,          # connect(machine.v, avr.v)
        avr.vs ~ pss.vs,            # connect(pss.vs, avr.vs)
        pss.vSI ~ machine.w,        # connect(pss.vSI, machine.w)
        avr.vf0 ~ machine.vf0,      # connect(machine.vf0, avr.vf0)
    ]
    extend(System(eqs, t, [], []; name, systems = [machine; systems]), base)
end
