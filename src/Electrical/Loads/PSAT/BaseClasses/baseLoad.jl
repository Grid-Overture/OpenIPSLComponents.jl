# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Loads/PSAT/BaseClasses/baseLoad.mo (partial; extends Electrical/Essentials/pfComponent.mo)
# Omitted: displayPF (disabled), the unused protected parameter CoB, graphical annotations. V_b and fn are accepted
# (pfComponent) and unused. Children extend this system with `@unpack v, anglev, P, Q, p = base` (F-20).
# Deviation (F-16): the bilinear definitions  P = p.vr*p.ir + p.vi*p.ii  and  Q = p.vi*p.ir - p.vr*p.ii  are written
# solved for the currents, ir = (P vr + Q vi)/v^2 and ii = (P vi - Q vr)/v^2 (the same relation for v != 0), so that
# ModelingToolkit's tearing never lands on the spurious v = 0 branch. The batch-0 VoltageDependent.jl carries the
# same two equations flattened.

@component function baseLoad(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0, Sn = S_b)
    pars = @parameters begin
        S_b = S_b, [description = "System base power (VA)"]
        V_b = V_b, [description = "Base voltage of the bus (V)"]
        fn = fn, [description = "System frequency (Hz)"]
        P_0 = P_0, [description = "Initial active power (W)"]
        Q_0 = Q_0, [description = "Initial reactive power (var)"]
        v_0 = v_0, [description = "Initial voltage magnitude (pu)"]
        angle_0 = angle_0, [description = "Initial voltage angle (rad)"]
        Sn = Sn, [description = "Power rating (VA)"]
    end
    systems = @named begin
        p = PwPin()
    end
    vars = @variables begin
        v(t), [description = "Voltage magnitude (pu)"]
        anglev(t), [description = "Voltage angle (rad)"]
        P(t), [description = "Active power (pu)"]
        Q(t), [description = "Reactive power (pu)"]
    end
    eqs = Equation[
        p.ir ~ (P * p.vr + Q * p.vi) / (p.vr^2 + p.vi^2),   # P = p.vr*p.ir + p.vi*p.ii (see header)
        p.ii ~ (P * p.vi - Q * p.vr) / (p.vr^2 + p.vi^2),   # Q = p.vi*p.ir - p.vr*p.ii
        v ~ sqrt(p.vr^2 + p.vi^2),
        anglev ~ atan(p.vi, p.vr),   # atan2(p.vi, p.vr)
    ]
    # v(start = v_0), anglev(start = angle_0), P(start = P_0/S_b), Q(start = Q_0/S_b),
    # p(vr(start = v_0*cos(angle_0)), vi(start = v_0*sin(angle_0)))
    System(eqs, t, vars, pars; name, systems,
        guesses = Dict(v => v_0, anglev => angle_0, P => P_0 / S_b, Q => Q_0 / S_b,
            p.vr => v_0 * cos(angle_0), p.vi => v_0 * sin(angle_0)))
end
