# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Wind/PSAT/PSAT_Type_3/PSAT_WT.mo (extends nothing: neither pfComponent nor
# SystemBase; its own V_0, angle_0, P_0, Q_0 in pu, S_b, V_b, fn)
# Blocks, with the names of the .mo: elecDyn = ElecDynBlk, elecCircuit = ElecBlk, windBlk1 = WindBlk, mechaBlk1 =
# MechaBlk, pitchControl1 = PitchControl. Ports: the pin `pin`, the input `Wind_Speed`; the outputs `Vbus`,
# `Anglebus`, `P`, `Q` are the aliases of elecCircuit's variables. The machine is scaled to the **PSAT bases**
# `S_b/Pnom` (`Rs = Rs_machine*S_b/Pnom`, ..., `Hm = Hm_machine*Pnom/S_b`, the limits `Pmax = Pnom/S_b`, ...), not
# with a `CoB`; the protected parameters are computed once here in dependency order (`iqr0` before `ids0`/`iqs0`,
# which read it: the .mo declares them out of order) and passed to the four children as numbers, whose own
# defaults (`Rs = 0.1`, `Xm = 30`, `Pnom = 10`, ...) the .mo overrides the same way. `V_b` only reaches `Vbase` of
# the children, which read it nowhere (inert); `nblades` is declared and unused (sic). `float()` on every Real
# (the Test passes `Pnom = 10`, `V_b = 1`, F-21). `iqr_max = -x1*Pmin/Xm` is identically 0.
# Omitted: the `import`, graphical annotations.

@component function PSAT_WT(; name, V_0 = 1, angle_0 = -0.00243, P_0 = 0.0160000000000082, Q_0 = 0.030527374471207,
        S_b = 100000000, V_b = 400e3, Pnom = 10000000, fn = 50, rho = 1.225, vw_base = 15, Rs_machine = 0.01,
        Xs_machine = 0.1, Rr_machine = 0.01, Xr_machine = 0.08, Xm_machine = 3, Hm_machine = 3, Kp = 10, Tp = 3,
        Kv = 10, Te = 0.01, l = 75, poles = 2, nblades = 3, ngb = 0.01123596)
    V_0, angle_0, P_0, Q_0, S_b, V_b, Pnom, fn, rho, vw_base, Rs_machine, Xs_machine, Rr_machine, Xr_machine =
        float.((V_0, angle_0, P_0, Q_0, S_b, V_b, Pnom, fn, rho, vw_base, Rs_machine, Xs_machine, Rr_machine, Xr_machine))
    Xm_machine, Hm_machine, Kp, Tp, Kv, Te, l, ngb = float.((Xm_machine, Hm_machine, Kp, Tp, Kv, Te, l, ngb))
    # the protected parameters of the .mo, in dependency order
    Rs = Rs_machine * S_b / Pnom
    Xs = Xs_machine * S_b / Pnom
    Rr = Rr_machine * S_b / Pnom
    Xr = Xr_machine * S_b / Pnom
    Xm = Xm_machine * S_b / Pnom
    Hm = Hm_machine * Pnom / S_b
    Pmax_machine = 1.0
    Pmin_machine = 0.0
    Qmax_machine = 0.7
    Qmin_machine = -0.7
    Pmax = Pmax_machine * Pnom / S_b
    Pmin = Pmin_machine * Pnom / S_b
    Qmax = Qmax_machine * Pnom / S_b
    Qmin = Qmin_machine * Pnom / S_b
    x1 = Xs + Xm
    x2 = Xr + Xm
    iqr_max = -x1 * Pmin / Xm
    iqr_min = -Pmax * x1 / Xm
    idr_min = (-Qmax * x1 / Xm) - x1 / Xm^2
    idr_max = (-Qmin * x1 / Xm) - x1 / Xm^2
    theta_max = 0.78539816339
    theta_min = 0.0
    omega_m0 = min(max(0.5 * P_0 * S_b / Pnom + 0.5, 0.5), 1)
    i2Hm = 1 / (2 * Hm)
    wbase = 2 * pi * fn / poles
    k = x1 * Pnom / V_0 / Xm / S_b
    theta_p0 = 0.0
    vds0 = -V_0 * sin(angle_0)
    vqs0 = V_0 * cos(angle_0)
    iqr0 = -x1 * Pnom * (2 * omega_m0 - 1) / V_0 / Xm / S_b / omega_m0
    ids0 = ((-vds0^2) + vds0 * Xm * iqr0 - x1 * Q_0) / (Rs * vds0 - x1 * vqs0)
    iqs0 = ((-vds0 * vqs0) + vqs0 * Xm * iqr0 - Rs * Q_0) / (Rs * vds0 - x1 * vqs0)
    idr0 = -(vqs0 + Rs * iqs0 + x1 * ids0) / Xm
    vdr0 = (-Rr * idr0) + (1 - omega_m0) * (x2 * iqr0 + Xm * iqs0)
    vqr0 = (-Rr * iqr0) - (1 - omega_m0) * (x2 * idr0 + Xm * ids0)
    systems = @named begin
        pin = PwPin()
        elecDyn = ElecDynBlk(; Sbase = S_b, Vbus0 = V_0, angle_0, Pc = P_0, Qc = Q_0, omega_m0, Pnom, Vbase = V_b,
            freq = fn, Rs, Xs, Rr, Xr, Xm, Hm, x1, x2, i2Hm, wbase, k, poles, ids0, iqs0, idr0, iqr0, vds0, vqs0, vdr0,
            vqr0, Kv, Te, idr_max, idr_min, iqr_max, iqr_min)
        elecCircuit = ElecBlk(; Sbase = S_b, Vbus0 = V_0, angle_0, Pc = P_0, Qc = Q_0, omega_m0, Pnom, Vbase = V_b,
            freq = fn, Rs, Xs, Rr, Xr, Xm, Hm, x1, i2Hm, wbase, k, poles, ids0, iqs0, idr0, iqr0, vds0, vqs0, vdr0, vqr0)
        windBlk1 = WindBlk(; vw_base, rho, Sbase = S_b, ngb, poles, freq = fn, wbase, l)
        mechaBlk1 = MechaBlk(; Sbase = S_b, Pnom, Hm, Pc = P_0)
        pitchControl1 = PitchControl(; Kp, Tp, theta_p0, theta_p_max = theta_max, theta_p_min = theta_min)
    end
    pars = @parameters begin
        V_0 = V_0, [description = "Voltage magnitude (pu)"]
        angle_0 = angle_0, [description = "Voltage angle (rad)"]
        P_0 = P_0, [description = "Active power (pu)"]
        Q_0 = Q_0, [description = "Reactive power (pu)"]
        S_b = S_b, [description = "System base power (VA)"]
        V_b = V_b, [description = "Voltage rating (V; inert)"]
        Pnom = Pnom, [description = "Nominal Power (VA)"]
        fn = fn, [description = "Frequency rating (Hz)"]
        rho = rho, [description = "Air Density (kg/m3)"]
        vw_base = vw_base, [description = "Nominal wind speed (m/s)"]
        Rs_machine = Rs_machine, [description = "Stator Resistance (pu of Pnom)"]
        Xs_machine = Xs_machine, [description = "Stator Reactance (pu of Pnom)"]
        Rr_machine = Rr_machine, [description = "Rotor Resitance (pu of Pnom)"]
        Xr_machine = Xr_machine, [description = "Rotor Reactance (pu of Pnom)"]
        Xm_machine = Xm_machine, [description = "Magnetisation reactance (pu of Pnom)"]
        Hm_machine = Hm_machine, [description = "Inertia (s, on Pnom)"]
        Kp = Kp, [description = "Pitch control gain"]
        Tp = Tp, [description = "Pitch control time constant (s)"]
        Kv = Kv, [description = "Voltage control gain"]
        Te = Te, [description = "Power Control time constant (s)"]
        l = l, [description = "Blade length (m)"]
        poles = poles, [description = "Number of poles-pair"]
        nblades = nblades, [description = "Number of blades (unused)"]
        ngb = ngb, [description = "Gear box ratio"]
        Rs = Rs
        Xs = Xs
        Rr = Rr
        Xr = Xr
        Xm = Xm
        Hm = Hm
        Pmax_machine = Pmax_machine
        Pmin_machine = Pmin_machine
        Qmax_machine = Qmax_machine
        Qmin_machine = Qmin_machine
        Pmax = Pmax
        Pmin = Pmin
        Qmax = Qmax
        Qmin = Qmin
        x1 = x1
        x2 = x2
        iqr_max = iqr_max
        iqr_min = iqr_min
        idr_min = idr_min
        idr_max = idr_max
        theta_max = theta_max
        theta_min = theta_min
        omega_m0 = omega_m0
        i2Hm = i2Hm
        wbase = wbase
        k = k
        theta_p0 = theta_p0
        ids0 = ids0
        iqs0 = iqs0
        idr0 = idr0
        iqr0 = iqr0
        vds0 = vds0
        vqs0 = vqs0
        vdr0 = vdr0
        vqr0 = vqr0
    end
    vars = @variables begin
        Wind_Speed(t), [description = "Wind speed input (pu of vw_base)"]
        Vbus(t), [description = "Bus voltage magnitude"]
        Anglebus(t), [description = "Bus voltage angle"]
        P(t), [description = "Active power"]
        Q(t), [description = "Reactive power"]
    end
    eqs = Equation[
        Vbus ~ elecCircuit.Vbus,                     # Types.PerUnit Vbus = elecCircuit.Vbus
        Anglebus ~ elecCircuit.Anglebus,
        P ~ elecCircuit.p,
        Q ~ elecCircuit.q,
        connect(pin, elecCircuit.pin),
        mechaBlk1.omega_m ~ elecDyn.omega_m,         # connect(mechaBlk1.omega_m, elecDyn.omega_m)
        elecDyn.Vbus ~ elecCircuit.Vbus,             # connect(elecDyn.Vbus, elecCircuit.Vbus)
        elecDyn.idr ~ elecCircuit.idr,               # connect(elecDyn.idr, elecCircuit.idr)
        elecDyn.iqr ~ elecCircuit.iqr,               # connect(elecDyn.iqr, elecCircuit.iqr)
        mechaBlk1.omega_m ~ elecCircuit.omega_m,     # connect(mechaBlk1.omega_m, elecCircuit.omega_m)
        mechaBlk1.Tel ~ elecCircuit.Tel,             # connect(mechaBlk1.Tel, elecCircuit.Tel)
        pitchControl1.theta_p ~ windBlk1.theta_p,    # connect(pitchControl1.theta_p, windBlk1.theta_p)
        windBlk1.Tm ~ mechaBlk1.Tm,                  # connect(windBlk1.Tm, mechaBlk1.Tm)
        mechaBlk1.omega_m ~ windBlk1.omega_m,        # connect(mechaBlk1.omega_m, windBlk1.omega_m)
        Wind_Speed ~ windBlk1.vw,                    # connect(Wind_Speed, windBlk1.vw)
        pitchControl1.omega_m ~ mechaBlk1.omega_m,   # connect(pitchControl1.omega_m, mechaBlk1.omega_m)
    ]
    System(eqs, t, vars, pars; name, systems)
end
