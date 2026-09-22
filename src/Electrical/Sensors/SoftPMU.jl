# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Sensors/SoftPMU.mo: a PMU measuring phasors on a line.
# Two PwPins, `p` and `n`, connected to each other inside the model (`connect(p, n)`), so the device is
# electrically transparent: same voltage, and the two pin currents sum to zero.
# Blocks: fCalc = NonElectrical.Nonlinear.FrequencyCalc (real_start = vr_0, imag_start = vi_0, start_guess = true,
# Ts). Omitted: graphical annotations.
# `v_0`, `angle_0` and `Ts` are forwarded to `FrequencyCalc`, whose four initial-value parameters reach nothing
# (F-89): the block's two derivative stages are the analytic `Modelica.Blocks.Continuous.Der`. They are kept
# because the .mo declares and passes them (rule 5).
# `fn` defaults to the outer SystemBase's, as in the .mo.

@component function SoftPMU(; name, v_0 = 1, angle_0 = 0, Ts = 0.01, fn = 50, S_b = 100e6)   # S_b: SysData's, unused
    v_0, angle_0, Ts, fn = float.((v_0, angle_0, Ts, fn))
    vr_0 = v_0 * cos(angle_0)
    vi_0 = v_0 * sin(angle_0)
    Tsn = Ts
    pars = @parameters begin
        v_0 = v_0, [description = "Voltage magnitude initial value (pu)"]
        angle_0 = angle_0, [description = "Voltage angle initial value (rad)"]
        Ts = Ts, [description = "Derivative smoothing filter time constant (s)"]
        fn = fn, [description = "System base frequency (Hz)"]
        vr_0 = vr_0
        vi_0 = vi_0
    end
    systems = @named begin
        p = PwPin()
        n = PwPin()
        fCalc = FrequencyCalc(; real_start = vr_0, imag_start = vi_0, start_guess = true, Ts = Tsn)
    end
    vars = @variables begin
        Vr(t), [description = "real part of the voltage phasor (pu)"]
        Vi(t), [description = "imaginary part of the voltage phasor (pu)"]
        Ir(t), [description = "real part of the current phasor (pu)"]
        Ii(t), [description = "imaginary part of the current phasor (pu)"]
        freq(t), [description = "frequency estimate (Hz)"]
    end
    eqs = Equation[
        Vr ~ p.vr,
        Vi ~ p.vi,
        Ir ~ p.ir,
        Ii ~ p.ii,
        connect(p, n),   # connect(p, n): the model is a short between its own two pins
        fCalc.real_part ~ p.vr,
        fCalc.imag_part ~ p.vi,
        freq ~ fCalc.y / (2 * pi) + fn,   # C.pi of the .mo
    ]
    System(eqs, t, vars, pars; name, systems)
end
