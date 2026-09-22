# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Renewables/PSSE/InverterInterface/BaseClasses/BaseREGC.mo (partial)
# extends: Electrical/Essentials/pfComponent.mo (enablefn = enableV_b = false -- both inert, kept as keyword
# arguments for uniformity; `M_b = SysData.S_b` by default, i.e. M_b = S_b through the child's `outer`).
# The base of the WECC inverter interface: the grid pin, the two current commands, the two power outputs, the five
# initialization outputs, the terminal voltage output and the three algebraic equations of the `.mo`.
# The protected derived parameters (p0, q0, vr0, vi0, ir0, ii0, Isr0, Isi0, Ip0, Iq0, CoB) are computed in Julia in
# the `.mo`'s own order and declared as `@parameters` here, as `PSSE_baseMachine` does; a child that needs their
# *numeric* value for a sub-block's `y_start` recomputes it from its own keyword arguments (F-22).
# The pin's `start` modifiers and the `start` of `delta`, `VT` and `anglev` are `guesses`, never metadata
# defaults (F-16).
# `atan2(p.vi, p.vr)` is `atan(p.vi, p.vr)`, and `delta = anglev` is literal (sic: `delta` here is an alias of the
# bus voltage angle, not a rotor angle).
# Omitted: the `import Complex`/`ComplexMath` lines (no Complex variable survives), displayPF, graphical annotations.

@component function BaseREGC(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        M_b = nothing, Tg = 0.02, rrpwr = 10, Brkpt = 0.9, Zerox = 0.5, Lvpl1 = 1.22, Volim = 1.2,
        lvpnt1 = 0.8, lvpnt0 = 0.4, Iolim = -1.3, Tfltr = 0.02, Khv = 0.7, Iqrmax = 9999, Iqrmin = -9999)
    S_b, V_b, fn, P_0, Q_0, v_0, angle_0 = float.((S_b, V_b, fn, P_0, Q_0, v_0, angle_0))
    M_b = M_b === nothing ? S_b : float(M_b)            # M_b = SysData.S_b, i.e. M_b = S_b
    Tg, rrpwr, Brkpt, Zerox, Lvpl1, Volim = float.((Tg, rrpwr, Brkpt, Zerox, Lvpl1, Volim))
    lvpnt1, lvpnt0, Iolim, Tfltr, Khv, Iqrmax, Iqrmin =
        float.((lvpnt1, lvpnt0, Iolim, Tfltr, Khv, Iqrmax, Iqrmin))
    n = regc_init(P_0, Q_0, v_0, angle_0, M_b, S_b)     # the protected parameters, in the .mo's order
    base = pfComponent(; name, S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    pars = @parameters begin
        M_b = M_b, [description = "Machine base power (VA)"]
        Tg = Tg, [description = "Converter time constant (s)"]
        rrpwr = rrpwr, [description = "Low Voltage Power Logic (LVPL) ramp rate limit"]
        Brkpt = Brkpt, [description = "LVPL characteristic voltage 2"]
        Zerox = Zerox, [description = "LVPL characteristic voltage 1"]
        Lvpl1 = Lvpl1, [description = "LVPL gain"]
        Volim = Volim, [description = "Voltage limit for high voltage reactive current management"]
        lvpnt1 = lvpnt1, [description = "High voltage point for low voltage active current management"]
        lvpnt0 = lvpnt0, [description = "Low voltage point for low voltage active current management"]
        Iolim = Iolim, [description = "Current limit for high voltage reactive current management"]
        Tfltr = Tfltr, [description = "Voltage filter time constant for low voltage active current management (s)"]
        Khv = Khv, [description = "Overvoltage compensation gain"]
        Iqrmax = Iqrmax, [description = "Upper limit on rate of change for reactive current"]
        Iqrmin = Iqrmin, [description = "Lower limit on rate of change for reactive current"]
        p0 = n.p0, [description = "Initial active power (machine base)"]
        q0 = n.q0, [description = "Initial reactive power (machine base)"]
        vr0 = n.vr0
        vi0 = n.vi0
        ir0 = n.ir0
        ii0 = n.ii0
        Isr0 = n.Isr0, [description = "Source current re M_b"]
        Isi0 = n.Isi0, [description = "Source current im M_b"]
        Ip0 = n.Ip0
        Iq0 = n.Iq0
        CoB = n.CoB, [description = "Change of base"]
    end
    systems = @named begin
        p = PwPin()
    end
    vars = @variables begin
        Iqcmd(t), [description = "Imaginary Command Current"]
        Ipcmd(t), [description = "Real Command Current"]
        IQ0(t), [description = "Initial Reactive Power"]
        IP0(t), [description = "Initial Active Power"]
        V_0(t), [description = "Initial Terminal Voltage Magnitude"]
        q_0(t), [description = "Initial Reactive Power"]
        p_0(t), [description = "Initial Active Power"]
        V_t(t), [description = "Terminal Voltage Magnitude"]
        Pgen(t), [description = "Active Power injection"]
        Qgen(t), [description = "Reactive Power injection"]
        delta(t)
        VT(t), [description = "Bus voltage magnitude"]
        anglev(t), [description = "Bus voltage angle"]
    end
    eqs = Equation[
        anglev ~ atan(p.vi, p.vr),
        VT ~ sqrt(p.vr * p.vr + p.vi * p.vi),
        delta ~ anglev,
    ]
    guesses = Dict(p.vr => n.vr0, p.vi => n.vi0, p.ir => -n.ir0 * n.CoB, p.ii => -n.ii0 * n.CoB,
        delta => angle_0, VT => v_0, anglev => angle_0)
    extend(System(eqs, t, vars, pars; name, systems, guesses), base)
end

# The protected parameters of BaseREGC.mo, in its own order. A child recomputes them with this function rather than
# reading the base's symbols, because a sub-block's `y_start` needs the number (F-22); BaseREPC has the same block.
function regc_init(P_0, Q_0, v_0, angle_0, M_b, S_b)
    p0 = P_0 / M_b
    q0 = Q_0 / M_b
    vr0 = v_0 * cos(angle_0)
    vi0 = v_0 * sin(angle_0)
    ir0 = (p0 * vr0 + q0 * vi0) / (vr0^2 + vi0^2)
    ii0 = (p0 * vi0 - q0 * vr0) / (vr0^2 + vi0^2)
    Isr0 = ir0
    Isi0 = ii0
    Ip0 = Isr0 * cos(-angle_0) - Isi0 * sin(-angle_0)
    Iq0 = Isr0 * sin(-angle_0) + cos(-angle_0) * Isi0
    (; p0, q0, vr0, vi0, ir0, ii0, Isr0, Isi0, Ip0, Iq0, CoB = M_b / S_b)
end
