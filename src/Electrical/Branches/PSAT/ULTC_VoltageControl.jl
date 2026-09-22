# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Branches/PSAT/ULTC_VoltageControl.mo
# Continuous under-load tap changer with secondary voltage control. `initial equation m = m0` is the initial condition
# of m. The `if m > m_max and der(m) > 0` / `elseif m < m_min and der(m) < 0` branches use, for der(m), the value it
# takes in the free branch, -H*m + K*(vm - vref) (PLAN-02); the effective ratio m_lim = m_max / m_min / m selects the
# network equations, written solved for the currents like TwoWindingTransformer.jl (F-21). `vm(start = v_0)` is a
# guess. S_b is a plain parameter here (100e6 in the .mo, not SysData). Omitted: graphical annotations.

@component function ULTC_VoltageControl(; name, S_b = 100e6, Vbus1 = 400e3, Vbus2 = 100e3, Sn = 100e6, Vn = 400e3, rT = 0.01,
        xT = 0.2, v_ref = 1.0, v_0 = 1.008959700699460, kT = 4, m0 = 0.98, m_max = 0.98, m_min = 0.9785, H = 0.001, K = 0.10)
    S_b, Vbus1, Vbus2, Sn, Vn, rT, xT, v_ref, v_0, kT, m0, m_max, m_min, H, K =
        float.((S_b, Vbus1, Vbus2, Sn, Vn, rT, xT, v_ref, v_0, kT, m0, m_max, m_min, H, K))   # F-21
    V2 = Vn / kT
    Zn = Vn^2 / Sn
    Zb = Vbus1^2 / S_b
    r = rT * Zn / Zb
    x = xT * Zn / Zb
    vref = v_ref * (V2 / Vbus2)
    pars = @parameters begin
        S_b = S_b, [description = "System base power (VA)"]
        Vbus1 = Vbus1, [description = "Sending end bus nominal voltage (V)"]
        Vbus2 = Vbus2, [description = "Receiving end bus nominal voltage (V)"]
        Sn = Sn, [description = "Power rating (VA)"]
        Vn = Vn, [description = "Voltage rating (V)"]
        rT = rT, [description = "Transformer resistance (transformer base, pu)"]
        xT = xT, [description = "Transformer reactance (transformer base, pu)"]
        v_ref = v_ref, [description = "Reference voltage (pu)"]
        v_0 = v_0, [description = "Initial voltage magnitude of the controlled bus (pu)"]
        kT = kT, [description = "Nominal tap ratio (V1/V2)"]
        m0 = m0, [description = "Initial tap ratio (pu/pu)"]
        m_max = m_max, [description = "Maximum tap ratio (pu/pu)"]
        m_min = m_min, [description = "Minimum tap ratio (pu/pu)"]
        H = H, [description = "Integral deviation (pu)"]
        K = K, [description = "Inverse time constant (1/s)"]
        V2 = V2, [description = "Secondary voltage (V)"]
        Zn = Zn, [description = "Transformer base impedance (Ohm)"]
        Zb = Zb, [description = "System base impedance (Ohm)"]
        r = r, [description = "Resistance (system base, pu)"]
        x = x, [description = "Reactance (system base, pu)"]
        vref = vref, [description = "Reference voltage on the secondary base (pu)"]
    end
    systems = @named begin
        p = PwPin()
        n = PwPin()
    end
    vars = @variables begin
        m(t), [description = "Tap ratio (pu)"]
        vk(t), [description = "Voltage at primary (pu)"]
        vm(t), [description = "Voltage at secondary (pu)"]
        anglevk(t), [description = "Angle at primary (rad)"]
        anglevm(t), [description = "Angle at secondary (rad)"]
    end
    dm = (-H * m) + K * (vm - vref)   # der(m) in the free branch
    at_max = (m > m_max) & (dm > 0)
    at_min = (m < m_min) & (dm < 0)
    m_lim = ifelse(at_max, m_max, ifelse(at_min, m_min, m))
    # r*p.ir - x*p.ii = A, x*p.ir + r*p.ii = B  ->  p.ir = (r A + x B)/(r^2 + x^2), p.ii = (r B - x A)/(r^2 + x^2)
    Ap, Bp = 1 / m_lim^2 * p.vr - 1 / m_lim * n.vr, 1 / m_lim^2 * p.vi - 1 / m_lim * n.vi
    An, Bn = n.vr - 1 / m_lim * p.vr, n.vi - 1 / m_lim * p.vi
    eqs = Equation[
        vk ~ sqrt(p.vr^2 + p.vi^2),
        vm ~ sqrt(n.vr^2 + n.vi^2),
        anglevk ~ atan(p.vi, p.vr),   # atan2
        anglevm ~ atan(n.vi, n.vr),
        p.ir ~ (r * Ap + x * Bp) / (r^2 + x^2),
        p.ii ~ (r * Bp - x * Ap) / (r^2 + x^2),
        n.ir ~ (r * An + x * Bn) / (r^2 + x^2),
        n.ii ~ (r * Bn - x * An) / (r^2 + x^2),
        der(m) ~ ifelse(at_max | at_min, 0, dm),
    ]
    System(eqs, t, vars, pars; name, systems, initial_conditions = Dict(m => m0), guesses = Dict(vm => v_0))
end
