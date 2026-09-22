# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Branches/PSAT/ThreeWindingTransformer.mo
# Blocks: three PSAT TwoWindingTransformer (branch1 with the tap m, branch2/branch3 with m = 1), star-connected at
# the fictitious bus branch1.n. The branch impedances are computed before `@parameters` (F-22). SysData.S_b is the
# parameter S_b; fn (outer SystemBase) is accepted and unused. Omitted: graphical annotations.

@component function ThreeWindingTransformer(; name, S_b = 100e6, V_b = 40e3, Sn = 100e6, Vn = 40e3, r12 = 0.01, r13 = 0.01,
        r23 = 0.01, x12 = 0.1, x13 = 0.1, x23 = 0.1, m = 0.98, fn = 50)
    S_b, V_b, Sn, Vn, r12, r13, r23, x12, x13, x23, m = float.((S_b, V_b, Sn, Vn, r12, r13, r23, x12, x13, x23, m))   # F-21
    systems = @named begin
        b1 = PwPin()
        b2 = PwPin()
        b3 = PwPin()
        branch1 = TwoWindingTransformer(; S_b, V_b, Sn, Vn, rT = 0.5 * (r12 + r13 - r23), xT = 0.5 * (x12 + x13 - x23), m)
        branch2 = TwoWindingTransformer(; S_b, V_b, Sn, Vn, rT = 0.5 * (r12 + r23 - r13), xT = 0.5 * (x12 + x23 - x13))
        branch3 = TwoWindingTransformer(; S_b, V_b, Sn, Vn, rT = 0.5 * (r23 + r13 - r12), xT = 0.5 * (x23 + x13 - x12))
    end
    pars = @parameters begin
        S_b = S_b, [description = "System base power (VA)"]
        V_b = V_b, [description = "Sending end bus voltage (V)"]
        Sn = Sn, [description = "Power rating (VA)"]
        Vn = Vn, [description = "Voltage rating for transformer (V)"]
        r12 = r12, [description = "Resistance of the branch 1-2 (transformer base, pu)"]
        r13 = r13, [description = "Resistance of the branch 1-3 (transformer base, pu)"]
        r23 = r23, [description = "Resistance of the branch 2-3 (transformer base, pu)"]
        x12 = x12, [description = "Reactance of the branch 1-2 (transformer base, pu)"]
        x13 = x13, [description = "Reactance of the branch 1-3 (transformer base, pu)"]
        x23 = x23, [description = "Reactance of the branch 2-3 (transformer base, pu)"]
        m = m, [description = "Fixed tap ratio"]
    end
    vars = @variables begin
        v0(t), [description = "Voltage of the fictitious bus (pu)"]
        v1(t)
        v2(t)
        v3(t)
        anglev0(t), [description = "Angle of the fictitious bus (rad)"]
        anglev1(t)
        anglev2(t)
        anglev3(t)
    end
    eqs = Equation[
        v0 ~ sqrt(branch1.n.vr^2 + branch1.n.vi^2),
        v1 ~ sqrt(b1.vr^2 + b1.vi^2),
        v2 ~ sqrt(b2.vr^2 + b2.vi^2),
        v3 ~ sqrt(b3.vr^2 + b3.vi^2),
        anglev0 ~ atan(branch1.n.vi, branch1.n.vr),   # atan2
        anglev1 ~ atan(b1.vi, b1.vr),
        anglev2 ~ atan(b2.vi, b2.vr),
        anglev3 ~ atan(b3.vi, b3.vr),
        connect(branch1.p, b1),
        connect(branch1.n, branch2.p),
        connect(branch2.n, b2),
        connect(branch1.n, branch3.p),
        connect(branch3.n, b3),
    ]
    System(eqs, t, vars, pars; name, systems)
end
