# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Machines/PSSE/Plant.mo (extends Interfaces/Generator.mo)
# Framework for a plant: a machine plus an exciter, a governor and a PSS, all four `replaceable` over their partial
# base. In Julia a `replaceable` with component modifiers is the `mods` keyword of the transcribed compositions
# (`mods = (; machine = (; redeclare = GENROE, Tpd0 = 5, ...), governor = (; redeclare = ConstantPower), ...)`) and
# each component is built with the package's `redeclared`/`modified` helpers, so a Plant without the four redeclares
# does not compile - exactly as in Modelica, where the bases are partial.
# Modelica merges the modifiers of the `replaceable` declaration with those of the `redeclare` (MLS 3.4 section
# 7.3.2) and `modified` drops the declaration's; in Tests.Machines.PSSE.GEN all fourteen machine modifiers are
# overridden by the redeclare, so the two rules agree. A Test that relies on the merge needs an `F-##` and a fix to
# the helper. `zero` is a Julia function, so the Constant instance is `zero_` (as `const_` elsewhere); no oracle
# column refers to it. The thirteen causal connects are equalities, `connect(machine.p, pwPin)` stays a connect.
# Omitted: graphical annotations, the Documentation section.

@component function Plant(; name, S_b = 100e6, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0, mods = (;))
    @named base = Generator(; S_b, fn, P_0, Q_0, v_0, angle_0)
    @unpack pwPin = base
    machine = redeclared(mods, :machine, PSSE_baseMachine)(; name = :machine,
        modified(mods, :machine, (; M_b = 100e6, Tpd0 = 1, Tppd0 = 1, Tppq0 = 1, H = 1, D = 1, Xd = 0.01, Xq = 0.01,
            Xpd = 0.01, Xppd = 0.01, Xppq = 0.01, Xl = 0.01, S10 = 1, S12 = 1, S_b, fn))...)
    exciter = redeclared(mods, :exciter, BaseExciter)(; name = :exciter, modified(mods, :exciter, (;))...)
    governor = redeclared(mods, :governor, BaseGovernor)(; name = :governor, modified(mods, :governor, (;))...)
    pss = redeclared(mods, :pss, BasePSS)(; name = :pss, modified(mods, :pss, (;))...)
    @named zero_ = Constant(; k = 0)   # `zero` in the .mo
    systems = [machine, exciter, zero_, governor, pss]
    eqs = Equation[
        pss.V_S2 ~ governor.PMECH0,      # connect(pss.V_S2, governor.PMECH0)
        pss.V_S1 ~ machine.SPEED,        # connect(pss.V_S1, machine.SPEED)
        connect(machine.p, pwPin),
        exciter.XADIFD ~ machine.XADIFD, # connect(exciter.XADIFD, machine.XADIFD)
        machine.EFD0 ~ exciter.EFD0,     # connect(machine.EFD0, exciter.EFD0)
        exciter.ECOMP ~ machine.ETERM,   # connect(exciter.ECOMP, machine.ETERM)
        zero_.y ~ exciter.VUEL,          # connect(zero.y, exciter.VUEL)
        governor.PMECH ~ machine.PMECH,  # connect(governor.PMECH, machine.PMECH)
        governor.SPEED ~ machine.SPEED,  # connect(governor.SPEED, machine.SPEED)
        machine.PMECH0 ~ governor.PMECH0, # connect(machine.PMECH0, governor.PMECH0)
        exciter.EFD ~ machine.EFD,       # connect(exciter.EFD, machine.EFD)
        zero_.y ~ exciter.VOEL,          # connect(zero.y, exciter.VOEL)
        pss.VOTHSG ~ exciter.VOTHSG,     # connect(pss.VOTHSG, exciter.VOTHSG)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end
