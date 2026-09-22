# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Branches/PSAT/TwoWindingTransformer.mo
# Omitted: displayPF, tc (icon only), the display variables P12/P21/Q12/Q21 and graphical annotations.
# SysData.S_b (inner/outer) is the parameter S_b. Protected parameters are evaluated at construction.
# Deviation, Julia only (F-21, batch 2): the four branch equations  r*p.ir - x*p.ii = p.vr/m^2 - n.vr/m  (and the
# imaginary and n-side ones) are written solved for the currents, p.i = (A + jB)/(r + jx) with A + jB the voltage
# difference, as PwLine.jl does. In the residual form ModelingToolkit's tearing of the ThreeWindingTransformer (three
# transformers on a fictitious node, two PQvar loads) picked a pivot that vanishes at the initial guess and the
# initialization returned Inf. Same relation, same values (batch-0 tests and Example_3 unchanged).

@component function TwoWindingTransformer(; name, S_b = 100e6, V_b = 40e3, Sn = S_b, Vn = 40e3, rT = 0.01, xT = 0.1, m = 1.0, fn = 50)   # fn: outer SystemBase, unused here
    S_b, V_b, Sn, Vn, rT, xT, m = float.((S_b, V_b, Sn, Vn, rT, xT, m))   # Integer literals are Reals in Modelica; Sn*V_b^2 overflows Int64 (F-21)
    Zn = Vn^2 / Sn
    Zb = V_b^2 / S_b
    r = rT * Zn / Zb
    x = xT * Zn / Zb
    pars = @parameters begin
        S_b = S_b, [description = "System base power (VA)"]
        V_b = V_b, [description = "Sending end bus voltage (V)"]
        Sn = Sn, [description = "Power rating (VA)"]
        Vn = Vn, [description = "Voltage rating (V)"]
        rT = rT, [description = "Resistance (transformer base, pu)"]
        xT = xT, [description = "Reactance (transformer base, pu)"]
        m = m, [description = "Optional fixed tap ratio"]
        Zn = Zn, [description = "Transformer base impedance (Ohm)"]
        Zb = Zb, [description = "System base impedance (Ohm)"]
        r = r, [description = "Resistance (system base, pu)"]
        x = x, [description = "Reactance (system base, pu)"]
    end
    systems = @named begin
        p = PwPin()
        n = PwPin()
    end
    # r*p.ir - x*p.ii = A, x*p.ir + r*p.ii = B  ->  p.ir = (r A + x B)/(r^2 + x^2), p.ii = (r B - x A)/(r^2 + x^2)
    Ap, Bp = 1 / m^2 * p.vr - 1 / m * n.vr, 1 / m^2 * p.vi - 1 / m * n.vi
    An, Bn = n.vr - 1 / m * p.vr, n.vi - 1 / m * p.vi
    eqs = Equation[
        p.ir ~ (r * Ap + x * Bp) / (r^2 + x^2),
        p.ii ~ (r * Bp - x * Ap) / (r^2 + x^2),
        n.ir ~ (r * An + x * Bn) / (r^2 + x^2),
        n.ii ~ (r * Bn - x * An) / (r^2 + x^2),
    ]
    System(eqs, t, [], pars; name, systems)
end
