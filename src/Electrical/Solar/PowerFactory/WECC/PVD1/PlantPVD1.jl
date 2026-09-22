# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Solar/PowerFactory/WECC/PVD1/PlantPVD1.mo (extends Electrical/Essentials/pfComponent.mo:
# enablefn = enableS_b = enableangle_0 = enablev_0 = enableP_0 = enableQ_0 = true; V_b accepted and inert)
# Blocks, with the names of the .mo: pvd1 = Controller (`PVD1_Controller`, with Pref = P_0/M_b, Qref = Q_0/M_b,
# u_0 = v_0), static_generator = ElmGenstat(M_b, angle_0, pll_connected = false, v_0), staVmea = StaVmea(angle_0, fn).
# `S_b` and `fn` reach the children as keyword arguments (the `outer SystemBase`). The 22 PVD1 parameters keep
# the defaults of the .mo (`PqFlag = true`); `M_b` has none. Omitted: displayPF, graphical annotations.

@component function PlantPVD1(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        M_b, Imax = 1.1, PqFlag = true, Tg = 0.02, Xc = 0, Qmx = 0.328, Qmn = -0.328, v0 = 0.9, v1 = 1.1, dqdv = 0,
        fdbd = -99, Ddn = 0, vr_recov = 1, fr_recov = 1, Ft0 = 0.99, Ft1 = 0.995, Ft2 = 1.005, Ft3 = 1.01,
        Vt0 = 0.88, Vt1 = 0.9, Vt2 = 1.1, Vt3 = 1.2)
    S_b, V_b, fn, P_0, Q_0, v_0, angle_0, M_b = float.((S_b, V_b, fn, P_0, Q_0, v_0, angle_0, M_b))
    Imax, Tg, Xc, Qmx, Qmn, v0, v1, dqdv, fdbd, Ddn, vr_recov, fr_recov =
        float.((Imax, Tg, Xc, Qmx, Qmn, v0, v1, dqdv, fdbd, Ddn, vr_recov, fr_recov))
    Ft0, Ft1, Ft2, Ft3, Vt0, Vt1, Vt2, Vt3 = float.((Ft0, Ft1, Ft2, Ft3, Vt0, Vt1, Vt2, Vt3))
    base = pfComponent(; name, S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    systems = @named begin
        p = PwPin()
        pvd1 = PVD1_Controller(; Ddn, Ft0, Ft1, Ft2, Ft3, Imax, PqFlag, Pref = P_0 / M_b, Qmn, Qmx, Qref = Q_0 / M_b,
            Tg, Vt0, Vt1, Vt2, Vt3, Xc, dqdv, fdbd, fr_recov, u_0 = v_0, v0, v1, vr_recov)
        static_generator = ElmGenstat(; S_b, fn, M_b, angle_0, pll_connected = false, v_0)
        staVmea = StaVmea(; angle_0, fn)
    end
    pars = @parameters begin
        M_b = M_b, [description = "PV plant base power (VA)"]
        Imax = Imax, [description = "Maximum allowable total converter current (pu)"]
        Tg = Tg, [description = "Inverter current regulator time constant (s)"]
        Xc = Xc, [description = "Line drop compensation reactance (pu)"]
        Qmx = Qmx, [description = "Maximum reactive power (pu)"]
        Qmn = Qmn, [description = "Minimum reactive power (pu)"]
        v0 = v0, [description = "Low voltage threshold for Volt/Var Control (pu)"]
        v1 = v1, [description = "High voltage threshold for Volt/Var Control (pu)"]
        dqdv = dqdv, [description = "Voltage/Var droop compensation"]
        fdbd = fdbd, [description = "Frequency deadband over frequency response (pu)"]
        Ddn = Ddn, [description = "Down regulation droop"]
        vr_recov = vr_recov, [description = "Amount of generation to reconnect after voltage disconnection"]
        fr_recov = fr_recov, [description = "Amount of generation to reconnect after frequency disconnection"]
        Ft0 = Ft0, [description = "Frequency tripping repose curve point 0"]
        Ft1 = Ft1, [description = "Frequency tripping repose curve point 1"]
        Ft2 = Ft2, [description = "Frequency tripping repose curve point 2"]
        Ft3 = Ft3, [description = "Frequency tripping repose curve point 3"]
        Vt0 = Vt0, [description = "Voltage tripping repose curve point 0"]
        Vt1 = Vt1, [description = "Voltage tripping repose curve point 1"]
        Vt2 = Vt2, [description = "Voltage tripping repose curve point 2"]
        Vt3 = Vt3, [description = "Voltage tripping repose curve point 3"]
    end
    eqs = Equation[
        connect(static_generator.p, p),
        pvd1.Ip ~ static_generator.id_ref,       # connect(pvd1.Ip, static_generator.id_ref)
        pvd1.Iq ~ static_generator.iq_ref,       # connect(pvd1.Iq, static_generator.iq_ref)
        static_generator.v ~ pvd1.Vt,            # connect(static_generator.v, pvd1.Vt)
        static_generator.i ~ pvd1.It,            # connect(static_generator.i, pvd1.It)
        connect(staVmea.p, p),
        staVmea.fe ~ pvd1.freq,                  # connect(staVmea.fe, pvd1.freq)
    ]
    extend(System(eqs, t, [], pars; name, systems), base)
end
