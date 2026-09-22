# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Solar/PowerFactory/WECC/PVD1/Controller.mo (extends nothing); the function is
# `PVD1_Controller` because `Controller` repeats in `Solar/PowerFactory/DIgSILENT` (rule 6.5, PLAN-08).
# Blocks, with the names of the .mo: compensation = Gain(Xc), add, numerical_limit = Limiter(inf, 0.01), division,
# division1, qppriority = PQPriority(Imax, PqFlag), PCurrentController = FirstOrder(T = Tg, InitialOutput, k = 1,
# y_start = Pref/u_0), QCurrentController = FirstOrder(T = Tg, InitialOutput, **k = -1**, y_start = -Qref/u_0) (sic:
# the sign matches ElmGenstat's iq_ref), freq_ref = Constant(1), add2(k1 = -1), deadZone = DeadZone(inf, fdbd),
# frequency_droop = Gain(Ddn), active_power_reference = Constant(Pref), deadband_voltage = DeadZone(v1, v0),
# voltage_droop = Gain(dqdv), limiter = Limiter(Qmx, Qmn), add1, add4, reactive_power_reference = Constant(Qref),
# product, product1..4, frequency_tripping / voltage_tripping = GenerationTripping. Ports are plain variables
# (Vt, It, freq; Ip, Iq). `Qref`, `Pref`, `u_0`, `PqFlag` have no default (declared among the blocks in the .mo).
# With the defaults `fdbd = -99`, `Ddn = 0` the frequency droop is identically zero; the tripping curves multiply
# both current commands through `product3`. Omitted: graphical annotations.

@component function PVD1_Controller(; name, Imax = 1.1, PqFlag, Tg = 0.02, Xc = 0, Qmx = 0.328, Qmn = -0.328, v0 = 0.9,
        v1 = 1.1, dqdv = 0, fdbd = -99, Ddn = 0, vr_recov = 1, fr_recov = 1, Ft0 = 0.99, Ft1 = 0.995, Ft2 = 1.005,
        Ft3 = 1.01, Vt0 = 0.88, Vt1 = 0.9, Vt2 = 1.1, Vt3 = 1.2, Qref, Pref, u_0)
    Imax, Tg, Xc, Qmx, Qmn, v0, v1, dqdv, fdbd, Ddn, vr_recov, fr_recov =
        float.((Imax, Tg, Xc, Qmx, Qmn, v0, v1, dqdv, fdbd, Ddn, vr_recov, fr_recov))
    Ft0, Ft1, Ft2, Ft3, Vt0, Vt1, Vt2, Vt3, Qref, Pref, u_0 = float.((Ft0, Ft1, Ft2, Ft3, Vt0, Vt1, Vt2, Vt3, Qref, Pref, u_0))
    inf = Modelica.Constants.inf
    systems = @named begin
        compensation = Gain(; k = Xc)
        add = Add()
        numerical_limit = Limiter(; uMax = inf, uMin = 0.01)
        division = Division()
        qppriority = PQPriority(; Imax, PqFlag)
        division1 = Division()
        PCurrentController = FirstOrder(; T = Tg, initType = :InitialOutput, k = 1, y_start = Pref / u_0)
        QCurrentController = FirstOrder(; T = Tg, initType = :InitialOutput, k = -1, y_start = -Qref / u_0)
        freq_ref = OpenIPSLComponents.Constant(; k = 1)
        add2 = Add(; k1 = -1)
        deadZone = DeadZone(; uMax = inf, uMin = fdbd)
        frequency_droop = Gain(; k = Ddn)
        active_power_reference = OpenIPSLComponents.Constant(; k = Pref)
        deadband_voltage = DeadZone(; uMax = v1, uMin = v0)
        voltage_droop = Gain(; k = dqdv)
        limiter = Limiter(; uMax = Qmx, uMin = Qmn)
        add1 = Add()
        reactive_power_reference = OpenIPSLComponents.Constant(; k = Qref)
        add4 = Add()
        product1 = Product()
        product = Product()
        frequency_tripping = GenerationTripping(; Lv0 = Ft0, Lv1 = Ft1, Lv2 = Ft2, Lv3 = Ft3, recov = fr_recov)
        voltage_tripping = GenerationTripping(; Lv0 = Vt0, Lv1 = Vt1, Lv2 = Vt2, Lv3 = Vt3, recov = vr_recov)
        product2 = Product()
        product3 = Product()
        product4 = Product()
    end
    pars = @parameters begin
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
        Qref = Qref, [description = "Reactive power reference (pu)"]
        Pref = Pref, [description = "Active power reference (pu)"]
        u_0 = u_0, [description = "Initial voltage (pu)"]
    end
    vars = @variables begin
        Vt(t), [description = "Terminal voltage (pu)"]
        It(t), [description = "Terminal current (pu)"]
        freq(t), [description = "Frequency (pu)"]
        Ip(t), [description = "Active current command (pu)"]
        Iq(t), [description = "Reactive current command (pu)"]
    end
    eqs = Equation[
        It ~ compensation.u,                          # connect(It, compensation.u)
        compensation.y ~ add.u2,                      # connect(compensation.y, add.u2)
        Vt ~ add.u1,                                  # connect(Vt, add.u1)
        numerical_limit.u ~ Vt,                       # connect(numerical_limit.u, Vt)
        numerical_limit.y ~ division.u2,              # connect(numerical_limit.y, division.u2)
        division.y ~ qppriority.Iq,                   # connect(division.y, qppriority.Iq)
        division1.u2 ~ numerical_limit.y,             # connect(division1.u2, numerical_limit.y)
        division1.y ~ qppriority.Ip,                  # connect(division1.y, qppriority.Ip)
        freq ~ add2.u1,                               # connect(freq, add2.u1)
        deadZone.y ~ frequency_droop.u,               # connect(deadZone.y, frequency_droop.u)
        freq_ref.y ~ add2.u2,                         # connect(freq_ref.y, add2.u2)
        add2.y ~ deadZone.u,                          # connect(add2.y, deadZone.u)
        add.y ~ deadband_voltage.u,                   # connect(add.y, deadband_voltage.u)
        voltage_droop.u ~ deadband_voltage.y,         # connect(voltage_droop.u, deadband_voltage.y)
        add1.y ~ limiter.u,                           # connect(add1.y, limiter.u)
        voltage_droop.y ~ add1.u1,                    # connect(voltage_droop.y, add1.u1)
        reactive_power_reference.y ~ add1.u2,         # connect(reactive_power_reference.y, add1.u2)
        limiter.y ~ division.u1,                      # connect(limiter.y, division.u1)
        QCurrentController.y ~ Iq,                    # connect(QCurrentController.y, Iq)
        PCurrentController.y ~ Ip,                    # connect(PCurrentController.y, Ip)
        active_power_reference.y ~ add4.u2,           # connect(active_power_reference.y, add4.u2)
        frequency_droop.y ~ add4.u1,                  # connect(frequency_droop.y, add4.u1)
        add4.y ~ division1.u1,                        # connect(add4.y, division1.u1)
        product1.y ~ PCurrentController.u,            # connect(product1.y, PCurrentController.u)
        product1.u2 ~ qppriority.Ipcmd,               # connect(product1.u2, qppriority.Ipcmd)
        frequency_tripping.TrpLow ~ product.u1,       # connect(frequency_tripping.TrpLow, product.u1)
        frequency_tripping.TrpHigh ~ product.u2,      # connect(frequency_tripping.TrpHigh, product.u2)
        frequency_tripping.u ~ freq,                  # connect(frequency_tripping.u, freq)
        voltage_tripping.u ~ Vt,                      # connect(voltage_tripping.u, Vt)
        voltage_tripping.TrpLow ~ product2.u1,        # connect(voltage_tripping.TrpLow, product2.u1)
        voltage_tripping.TrpHigh ~ product2.u2,       # connect(voltage_tripping.TrpHigh, product2.u2)
        product.y ~ product3.u1,                      # connect(product.y, product3.u1)
        product2.y ~ product3.u2,                     # connect(product2.y, product3.u2)
        product3.y ~ product1.u1,                     # connect(product3.y, product1.u1)
        product4.y ~ QCurrentController.u,            # connect(product4.y, QCurrentController.u)
        qppriority.Iqcmd ~ product4.u1,               # connect(qppriority.Iqcmd, product4.u1)
        product4.u2 ~ product3.y,                     # connect(product4.u2, product3.y)
    ]
    System(eqs, t, vars, pars; name, systems)
end
