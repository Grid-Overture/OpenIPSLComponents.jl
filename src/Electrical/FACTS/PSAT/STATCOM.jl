# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/FACTS/PSAT/STATCOM.mo (extends Electrical/Essentials/pfComponent.mo with P_0 = 0),
# blocks as subsystems:
#   V             Modelica.Blocks.Sources.RealExpression (y = v)      written in the parent: `V.y ~ v` (F-22, point 2)
#   V_ref         Modelica.Blocks.Sources.RealExpression (y = v_ref)  a number, so it goes in the block
#   feedback      Modelica.Blocks.Math.Add3 (k1 = -1)                 -V.y + v_POD + V_ref.y
#   simpleLagLim  OpenIPSL.NonElectrical.Continuous.SimpleLagLim (K = Kr, T = Tr, y_start = i0,
#                                                                 outMax = i_max, outMin = i_min)   -> i_SH
# `In`, `I_b`, `i_max`, `i_min`, `vr0`, `vi0`, `i0`, `v_ref`, `u0` are Julia arithmetic in dependency order (`i0` and
# `v_ref` before `u0`, which the .mo declares first). `simpleLagLim(u(start = u0))` is a start value of a child's
# variable, so it is a `guess` of this parent (F-20).
# **Deviation of form (the third of the port, after the loads of F-16 and `PwLine` of F-21): the pin currents are
# written explicitly.** The .mo writes `0 = p.vr*p.ir + p.vi*p.ii`, `-Q = p.vi*p.ir - p.vr*p.ii` and `Q = i_SH*v`,
# two bilinear definitions with a spurious `v = 0` branch on which the current is arbitrary. Solving the pair for the
# currents (determinant `p.vr^2 + p.vi^2 = v^2`) gives `p.ir = -i_SH*p.vi/v`, `p.ii = i_SH*p.vr/v`, identical for
# `v != 0`: from `0 = p.vr*p.ir + p.vi*p.ii` and `-Q = p.vi*p.ir - p.vr*p.ii` with `Q = i_SH*v`,
#   p.ir = (0*p.vr - Q*p.vi)/v^2 = -i_SH*p.vi/v,   p.ii = (0*p.vi + Q*p.vr)/v^2 = i_SH*p.vr/v.
# `Q = i_SH*v` is kept as written.
# The RealInput/RealOutput ports v_POD and i_SH (protected in the .mo) are plain variables.
# Omitted: graphical annotations, displayPF.

@component function STATCOM(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 0, Q_0 = 0, v_0 = 1, angle_0 = 0,
        Sn = S_b, Vn = V_b, Kr = 0.1, Tr = 0.01, i_Max = 0.7, i_Min = -0.1)
    S_b, V_b, fn, P_0, Q_0, v_0, angle_0, Sn, Vn, Kr, Tr, i_Max, i_Min =
        float.((S_b, V_b, fn, P_0, Q_0, v_0, angle_0, Sn, Vn, Kr, Tr, i_Max, i_Min))   # F-21
    In = Sn / Vn
    I_b = S_b / V_b
    i_max = i_Max * In / I_b
    i_min = i_Min * In / I_b
    vr0 = v_0 * cos(angle_0)
    vi0 = v_0 * sin(angle_0)
    i0 = (Q_0 / S_b) / v_0
    v_ref = i0 / Kr + v_0
    u0 = v_ref - v_0
    Krn, Trn = Kr, Tr   # `SimpleLagLim` decides its degenerate branch in Julia from the numeric T (F-22, point 1)
    @named base = pfComponent(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    pars = @parameters begin
        Sn = Sn, [description = "Power rating (VA)"]
        Vn = Vn, [description = "Voltage rating (V)"]
        Kr = Kr, [description = "Regulator gain (pu/pu)"]
        Tr = Tr, [description = "Regulator time constant (s)"]
        i_Max = i_Max, [description = "Maximum current (device base, pu)"]
        i_Min = i_Min, [description = "Minimum current (device base, pu)"]
        In = In, [description = "Nominal current (device base, A)"]
        I_b = I_b, [description = "Base current (A)"]
        i_max = i_max, [description = "Max current (system base, pu)"]
        i_min = i_min, [description = "Min current (system base, pu)"]
        vr0 = vr0, [description = "Initial real voltage (pu)"]
        vi0 = vi0, [description = "Initial imaginary voltage (pu)"]
        i0 = i0, [description = "Initial current (pu)"]
        v_ref = v_ref, [description = "Reference voltage (pu)"]
        u0 = u0, [description = "Initial controller input (pu)"]
    end
    systems = @named begin
        p = PwPin()
        feedback = Add3(; k1 = -1)
        V = RealExpression(; expr = nothing)   # y = v: written in the parent
        V_ref = RealExpression(; expr = v_ref)
        simpleLagLim = SimpleLagLim(; K = Krn, T = Trn, y_start = i0, outMax = i_max, outMin = i_min)
    end
    vars = @variables begin
        v(t), [description = "Bus voltage magnitude (pu)"]
        Q(t), [description = "Injected reactive power (system base, pu)"]
        i_SH(t), [description = "STATCOM current (pu)"]
        v_POD(t), [description = "Power oscillation damping signal (pu)"]
    end
    eqs = Equation[
        v ~ sqrt(p.vr^2 + p.vi^2),
        p.ir ~ -i_SH * p.vi / v,     # 0 = p.vr*p.ir + p.vi*p.ii and -Q = p.vi*p.ir - p.vr*p.ii, solved (header)
        p.ii ~ i_SH * p.vr / v,
        Q ~ i_SH * v,
        i_SH ~ simpleLagLim.y,       # connect(simpleLagLim.y, i_SH)
        simpleLagLim.u ~ feedback.y, # connect(feedback.y, simpleLagLim.u)
        V.y ~ v,                     # RealExpression V(y = v)
        feedback.u1 ~ V.y,           # connect(V.y, feedback.u1)
        feedback.u3 ~ V_ref.y,       # connect(V_ref.y, feedback.u3)
        feedback.u2 ~ v_POD,         # connect(v_POD, feedback.u2)
    ]
    extend(System(eqs, t, vars, pars; name, systems,
            guesses = Dict(v => v_0, Q => Q_0 / S_b, i_SH => i0, v_POD => 0.0, p.vr => vr0, p.vi => vi0,
                simpleLagLim.u => u0)), base)
end
