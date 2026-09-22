# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Sources/SourceBehindImpedance/VoltageSources/VSourceIO.mo (extends BaseClasses/baseVoltageSource.mo)
# Voltage source behind an impedance with inputs uDEmag, uDEang (plain variables, `start = 0` as guesses) that vary
# the internal source. Blocks: Modelica.Blocks.Math.PolarToRectangular (p2R). `useEphasorInternalAsInput` is decided
# in Julia: true adds the inputs to the internal initial phasor (Er = Er0 + p2R.y_re, OpenIPSL's own formulation),
# false takes the inputs as the phasor itself. Omitted: graphical annotations.

@component function VSourceIO(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0, M_b = S_b,
        R_a = 1e-3, X_d = 0.2, useEphasorInternalAsInput = true)
    @named base = baseVoltageSource(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0, M_b, R_a, X_d)
    @unpack E, delta, Er, Ei, E0, delta0, Er0, Ei0 = base
    systems = @named begin
        p2R = PolarToRectangular()
    end
    vars = @variables begin
        uDEmag(t), [description = "Input to vary the voltage magnitude of the voltage source (pu)"]
        uDEang(t), [description = "Input to vary the angle of the voltage source (rad)"]
    end
    internal = useEphasorInternalAsInput ? Equation[
        delta ~ delta0 + uDEang,
        E ~ E0 + uDEmag,
        Er ~ Er0 + p2R.y_re,
        Ei ~ Ei0 + p2R.y_im,
    ] : Equation[
        delta ~ uDEang,
        E ~ uDEmag,
        Er ~ p2R.y_re,
        Ei ~ p2R.y_im,
    ]
    eqs = Equation[
        internal...,
        p2R.u_abs ~ uDEmag,   # connect(p2R.u_abs, uDEmag)
        p2R.u_arg ~ uDEang,   # connect(p2R.u_arg, uDEang)
    ]
    extend(System(eqs, t, vars, []; name, systems, guesses = Dict(uDEmag => 0.0, uDEang => 0.0)), base)
end
