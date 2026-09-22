# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Wind/PSAT/PSAT_Type_3/ElecBlk.mo (extends nothing)
# Blocks: none. Ports are plain variables (omega_m, idr, iqr -- the two inputs carry `start = idr0/iqr0`, guesses
# (F-20) --; Tel, Vbus) and the pin. The algebraic stator/rotor circuit of the DFIG in the dq frame
# (`vqs = pin.vr`, `vds = -pin.vi`). The parameters are declared in the order of the .mo; the derived ones are
# **reordered to their dependency order** as keyword defaults (`omega_m0`, `x1`, `vds0`, `vqs0`, `iqr0` before
# `ids0`, `iqs0`, `idr0`, `vdr0`, `vqr0`, as in MotorTypeV.jl). `Vbase`, `freq`, `wbase`, `k`, `Hm`, `i2Hm` are
# declared and read by no equation (sic, precedent MotorTypeV). `Anglebus = atan(pin.vi/pin.vr)` is the quotient
# `atan`, not atan2 (sic).
# Deviation (F-16, fifth explicit form of the port): the two bilinear pin equations `-p = vr*ir + vi*ii`,
# `-q = vi*ir - vr*ii` are written solved for the currents, `ir = -(p vr + q vi)/v^2`, `ii = -(p vi - q vr)/v^2`
# (the same relation for v != 0; `p`, `q` are fixed by the other equations), so that the tearing never lands on the
# v = 0 branch. Omitted: graphical annotations.

@component function ElecBlk(; name, Sbase = 100000000, Vbus0 = 1, angle_0 = -0.00243, Pc = 0.0160000000000082,
        Qc = 0.030527374471207, Pnom = 10, Vbase = 400000, freq = 50, Rs = 0.1, Xs = 1, Rr = 0.1, Xr = 0.8, Xm = 30,
        Hm = 0.3, poles = 2,
        omega_m0 = min(max(0.5 * Pc * Sbase / Pnom + 0.5, 0.5), 1), x1 = Xm + Xs, wbase = 2 * pi * freq / poles,
        k = x1 * Pnom / Vbus0 / Xm / Sbase, vds0 = -Vbus0 * sin(angle_0), vqs0 = Vbus0 * cos(angle_0),
        iqr0 = -x1 * Pnom * (2 * omega_m0 - 1) / Vbus0 / Xm / Sbase / omega_m0,
        ids0 = ((-vds0^2) + vds0 * Xm * iqr0 - x1 * Qc) / (Rs * vds0 - x1 * vqs0),
        iqs0 = ((-vds0 * vqs0) + vqs0 * Xm * iqr0 - Rs * Qc) / (Rs * vds0 - x1 * vqs0),
        idr0 = -(vqs0 + Rs * iqs0 + x1 * ids0) / Xm,
        vdr0 = (-Rr * idr0) + (1 - omega_m0) * ((Xm + Xr) * iqr0 + Xm * iqs0),
        vqr0 = (-Rr * iqr0) - (1 - omega_m0) * ((Xm + Xr) * idr0 + Xm * ids0), i2Hm = 1 / (2 * Hm))
    Sbase, Vbus0, angle_0, Pc, Qc, Pnom, Vbase, freq, Rs, Xs, Rr, Xr, Xm, Hm =
        float.((Sbase, Vbus0, angle_0, Pc, Qc, Pnom, Vbase, freq, Rs, Xs, Rr, Xr, Xm, Hm))
    omega_m0, x1, wbase, k, vds0, vqs0, iqr0, ids0, iqs0, idr0, vdr0, vqr0, i2Hm =
        float.((omega_m0, x1, wbase, k, vds0, vqs0, iqr0, ids0, iqs0, idr0, vdr0, vqr0, i2Hm))
    pars = @parameters begin
        Sbase = Sbase, [description = "Power Rating [Normalization Factor] (VA)"]
        Vbus0 = Vbus0, [description = "Voltage from Power Flow (pu)"]
        angle_0 = angle_0, [description = "Angle from Power Flow (rad)"]
        Pc = Pc, [description = "Active Power, PowerFlow (pu)"]
        Qc = Qc, [description = "Reactive Power, Power Flow (pu)"]
        omega_m0 = omega_m0
        Pnom = Pnom, [description = "Nominal Power (VA)"]
        Vbase = Vbase, [description = "Voltage rating (V; unused)"]
        freq = freq, [description = "frequency rating (Hz; unused)"]
        Rs = Rs, [description = "stator Resistance (pu)"]
        Xs = Xs, [description = "stator Reactance (pu)"]
        Rr = Rr, [description = "Rotor Resitance (pu)"]
        Xr = Xr, [description = "rotor Reactance (pu)"]
        Xm = Xm, [description = "magnetisation reactance (pu)"]
        Hm = Hm, [description = "inertia (s; unused)"]
        x1 = x1, [description = "stator plus magnetisation impedances"]
        wbase = wbase, [description = "basis for angular speed (unused)"]
        k = k, [description = "gain for iqr_off computation (unused)"]
        ids0 = ids0
        iqs0 = iqs0
        idr0 = idr0
        iqr0 = iqr0
        vds0 = vds0
        vqs0 = vqs0
        vdr0 = vdr0
        vqr0 = vqr0
        poles = poles, [description = "Number of poles-pair"]
        i2Hm = i2Hm, [description = "inverse inertia (unused)"]
    end
    systems = @named begin
        pin = PwPin()
    end
    vars = @variables begin
        omega_m(t), [description = "Rotor Speed"]
        idr(t), [description = "idr"]
        iqr(t), [description = "iqr"]
        Tel(t), [description = "Electrical Torque"]
        Vbus(t), [description = "Bus Voltage Magnitude"]
        vds(t), [description = "stator tension, in dq"]
        vqs(t), [description = "stator tension, in dq"]
        p(t), [description = "Active power"]
        q(t), [description = "Reactive Power"]
        ids(t), [description = "stator current, in dq"]
        iqs(t), [description = "stator current, in dq"]
        vdr(t), [description = "rotor voltage in dq"]
        vqr(t), [description = "rotor voltage in dq"]
        slip(t)
        Anglebus(t)
    end
    eqs = Equation[
        Anglebus ~ atan(pin.vi / pin.vr),
        Vbus ~ sqrt(vds^2 + vqs^2),
        vqs ~ pin.vr,
        vds ~ -pin.vi,
        pin.ir ~ -(p * pin.vr + q * pin.vi) / (pin.vr^2 + pin.vi^2),   # -p = pin.vr*pin.ir + pin.vi*pin.ii (see header)
        pin.ii ~ -(p * pin.vi - q * pin.vr) / (pin.vr^2 + pin.vi^2),   # -q = pin.vi*pin.ir - pin.vr*pin.ii
        p ~ vds * ids + vqs * iqs + vdr * idr + vqr * iqr,
        q ~ (-Xm * Vbus * idr / x1) - Vbus^2 / Xm,
        vds ~ (-Rs * ids) + x1 * iqs + Xm * iqr,
        vqs ~ (-Rs * iqs) - x1 * ids - Xm * idr,
        slip ~ 1 - omega_m,
        vdr ~ (-Rr * idr) + slip * (x1 * iqr + Xm * iqs),
        vqr ~ (-Rr * iqr) - slip * (x1 * idr + Xm * ids),
        Tel ~ Xm * (iqr * ids - idr * iqs),
    ]
    System(eqs, t, vars, pars; name, systems,
        guesses = Dict(idr => idr0, iqr => iqr0, vds => vds0, vqs => vqs0, ids => ids0, iqs => iqs0, vdr => vdr0, vqr => vqr0,
            pin.vr => vqs0, pin.vi => -vds0, Vbus => Vbus0, p => Pc, q => Qc))
end
