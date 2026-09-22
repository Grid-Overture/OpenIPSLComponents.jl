# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Branches/PSAT/PhaseShiftingTransformer.mo (with its nested model PhaseShifter)
# Blocks: the lot-0 TwoWindingTransformer and the phase shifter (a class nested in the .mo, a @component in this file).
# `inner pk` / `outer pk`: the shifter has its own variable pk and the parent writes `phaseShifter.pk ~ pk`.
# The shifter's `if alpha > alpha_max and der(pmes) > 0` uses der(pmes) = (pk - pmes)/Tm, identical in the three
# branches, so the condition is written on the sign of pk - pmes; the branches are `ifelse` without state events
# (the Test never reaches +-pi/2). The states pmes (start pmes0) and alpha (start alpha0) have no initial equation:
# guesses (F-20, F-28); OpenModelica fixes both at their start values and the Test does the same through `u0`.
# SysData.S_b is the parameter S_b; fn (outer SystemBase) is accepted and unused. Omitted: graphical annotations.

@component function PhaseShifter(; name, pref = 0.01, Kp = 0.5, Ki = 0.1, Tm = 0.001, alpha_max = pi / 2, alpha_min = -pi / 2,
        pmes0 = 0.01, alpha0 = 0)
    pref, Kp, Ki, Tm, alpha_max, alpha_min, pmes0, alpha0 = float.((pref, Kp, Ki, Tm, alpha_max, alpha_min, pmes0, alpha0))
    pars = @parameters begin
        pref = pref, [description = "Desired power flow (pu)"]
        Kp = Kp, [description = "Proportional gain"]
        Ki = Ki, [description = "Integral gain"]
        Tm = Tm, [description = "Measurement time constant (s)"]
        alpha_max = alpha_max, [description = "Maximum phase angle (rad)"]
        alpha_min = alpha_min, [description = "Minimum phase angle (rad)"]
        pmes0 = pmes0, [description = "Initial measured power flow (pu)"]
        alpha0 = alpha0, [description = "Initial phase shifting angle (rad)"]
    end
    systems = @named begin
        p = PwPin()
        n = PwPin()
    end
    vars = @variables begin
        pk(t), [description = "Actual secondary power flow (pu; outer, set by the parent)"]
        pmes(t), [description = "Measured power flow (pu)"]
        alpha(t), [description = "Shifting angle (rad)"]
    end
    at_max = (alpha > alpha_max) & (pk - pmes > 0)   # der(pmes) > 0
    at_min = (alpha < alpha_min) & (pk - pmes < 0)   # der(pmes) < 0
    a_eff = ifelse(at_max, alpha_max, ifelse(at_min, alpha_min, alpha))
    eqs = Equation[
        der(alpha) ~ ifelse(at_max | at_min, 0, Kp * (pk - pmes) / Tm + Ki * (pmes - pref)),
        der(pmes) ~ (pk - pmes) / Tm,
        p.vr ~ n.vr * cos(a_eff) - n.vi * sin(a_eff),
        p.vi ~ n.vr * sin(a_eff) + n.vi * cos(a_eff),
        p.ir + n.ir ~ 0,
        p.ii + n.ii ~ 0,
    ]
    System(eqs, t, vars, pars; name, systems, guesses = Dict(pmes => pmes0, alpha => alpha0))
end

@component function PhaseShiftingTransformer(; name, S_b = 100e6, V_b = 40e3, Sn = S_b, Vn = 40e3, rT = 0.01, xT = 0.1,
        m = 1.0, pref = 0.01, Kp = 0.5, Ki = 0.1, Tm = 0.001, alpha_max = pi / 2, alpha_min = -pi / 2, pmes0 = 0.01,
        alpha0 = 0, fn = 50)
    S_b, V_b, Sn, Vn, rT, xT, m = float.((S_b, V_b, Sn, Vn, rT, xT, m))   # F-21
    systems = @named begin
        twoWindingTransformer = TwoWindingTransformer(; S_b, V_b, Sn, Vn, rT, xT, m)
        phaseShifter = PhaseShifter(; pref, Kp, Ki, Tm, alpha_max, alpha_min, pmes0, alpha0)
        n = PwPin()
        p = PwPin()
    end
    pars = @parameters begin
        S_b = S_b, [description = "System base power (VA)"]
        V_b = V_b, [description = "Sending end bus voltage (V)"]
        Sn = Sn, [description = "Power rating (VA)"]
        Vn = Vn, [description = "Voltage rating (V)"]
        rT = rT, [description = "Resistance (transformer base, pu)"]
        xT = xT, [description = "Reactance (transformer base, pu)"]
        m = m, [description = "Optional fixed tap ratio"]
        pref = pref, [description = "Desired power flow (pu)"]
        Kp = Kp, [description = "Proportional gain"]
        Ki = Ki, [description = "Integral gain"]
        Tm = Tm, [description = "Measurement time constant (s)"]
        alpha_max = alpha_max, [description = "Maximum phase angle (rad)"]
        alpha_min = alpha_min, [description = "Minimum phase angle (rad)"]
        pmes0 = pmes0, [description = "Initial measured power flow (pu)"]
        alpha0 = alpha0, [description = "Initial phase shifting angle (rad)"]
    end
    vars = @variables begin
        pk(t), [description = "Actual primary power flow (pu; inner)"]
        anglevk(t), [description = "Angle at primary (rad)"]
        anglevm(t), [description = "Angle at secondary (rad)"]
        vk(t), [description = "Voltage at primary (pu)"]
        vm(t), [description = "Voltage at secondary (pu)"]
    end
    eqs = Equation[
        vk ~ sqrt(p.vr^2 + p.vi^2),
        vm ~ sqrt(n.vr^2 + n.vi^2),
        anglevk ~ atan(p.vi, p.vr),   # atan2
        anglevm ~ atan(n.vi, n.vr),
        pk ~ p.vr * p.ir + p.vi * p.ii,
        phaseShifter.pk ~ pk,   # inner/outer pk
        connect(twoWindingTransformer.p, p),
        connect(twoWindingTransformer.n, phaseShifter.p),
        connect(phaseShifter.n, n),
    ]
    System(eqs, t, vars, pars; name, systems)
end
