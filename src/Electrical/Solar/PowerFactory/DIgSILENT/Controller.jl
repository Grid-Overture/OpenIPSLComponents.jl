# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Solar/PowerFactory/DIgSILENT/Controller.mo (extends nothing); the function is
# `DIgSILENT_Controller` because `Controller` repeats in `Solar/PowerFactory/WECC/PVD1` (rule 6.5, PLAN-08).
# Blocks, with the names of the .mo: MPP_delay = FirstOrder(T = Tmpp, SteadyState)(vdcref), limiter = Limiter(inf,
# U_min), feedback1 (vdcin - limiter.y), filter = FirstOrder(T = Tr, SteadyState, y_start = 0),
# activePowerController = ActivePowerController(K = Kp, T = Tip, id0, yo_max = id_max, yo_min = id_min),
# voltage_measurement_delay = FirstOrder(T = Tr, InitialOutput, y_start = uac0)(uac), reference_voltage =
# Constant(uac0), feedback (duac), reactivePowerSupport = ReactivePowerSupport(Deadband, K_FRT, i0 = iq0, i_EEG,
# iq_max, iq_min), current_limiter = CurrentLimiter(Deadband, maxAbsCur, maxIq, i_EEG). Ports are plain variables
# (vdcref, uac, pred, vdcin; id_ref, iq_ref). `SteadyState` is `y = u` at t = 0 (MSL), not `y = 0`. Omitted:
# graphical annotations.

@component function DIgSILENT_Controller(; name, Kp = 0.005, Tip = 0.03, Tr = 0.001, Tmpp = 5, id_min = 0, id_max = 1,
        U_min = 200, iq_min = -1, iq_max = 1, Deadband = 0.1, K_FRT = 2, i_EEG = false, maxAbsCur = 1, maxIq = 1,
        uac0 = 1, iq0 = -0.2, id0 = 0.6)
    Kp, Tip, Tr, Tmpp, id_min, id_max, U_min, iq_min, iq_max, Deadband, K_FRT, maxAbsCur, maxIq, uac0, iq0, id0 =
        float.((Kp, Tip, Tr, Tmpp, id_min, id_max, U_min, iq_min, iq_max, Deadband, K_FRT, maxAbsCur, maxIq, uac0, iq0, id0))
    inf = Modelica.Constants.inf
    systems = @named begin
        feedback = Feedback()
        MPP_delay = FirstOrder(; T = Tmpp, initType = :SteadyState)
        voltage_measurement_delay = FirstOrder(; T = Tr, initType = :InitialOutput, y_start = uac0)
        reference_voltage = OpenIPSLComponents.Constant(; k = uac0)
        limiter = Limiter(; uMax = inf, uMin = U_min)
        feedback1 = Feedback()
        filter = FirstOrder(; T = Tr, initType = :SteadyState, y_start = 0)
        reactivePowerSupport = ReactivePowerSupport(; Deadband, K_FRT, i0 = iq0, i_EEG, iq_max, iq_min)
        current_limiter = CurrentLimiter(; Deadband, maxAbsCur, maxIq, i_EEG)
        activePowerController = ActivePowerController(; K = Kp, T = Tip, id0, yo_max = id_max, yo_min = id_min)
    end
    pars = @parameters begin
        Kp = Kp, [description = "Gain, Active Power PI-Controller"]
        Tip = Tip, [description = "Integration Time Constant, Active Power PI-Ctrl. (s)"]
        Tr = Tr, [description = "Measurement Delay (s)"]
        Tmpp = Tmpp, [description = "Time Delay MPP-Tracking (s)"]
        id_min = id_min, [description = "Min. Active Current Limit (pu)"]
        id_max = id_max, [description = "Max. Active Current Limit (pu)"]
        U_min = U_min, [description = "Minimal allowed DC-voltage (V)"]
        iq_min = iq_min, [description = "Min. Reactive Current Limit (pu)"]
        iq_max = iq_max, [description = "Max. Reactive Current Limit (pu)"]
        Deadband = Deadband, [description = "Deadband for Dynamic AC Voltage Support (pu)"]
        K_FRT = K_FRT, [description = "Gain for Dynamic AC Voltage Support"]
        maxAbsCur = maxAbsCur, [description = "Max. allowed absolute current (pu)"]
        maxIq = maxIq, [description = "Max.abs reactive current in normal operation (pu)"]
        uac0 = uac0, [description = "Initial voltage magnitude (pu)"]
        iq0 = iq0, [description = "Initial q-axis current (pu)"]
        id0 = id0, [description = "Initial d-axis current (pu)"]
    end
    vars = @variables begin
        vdcref(t), [description = "DC voltage reference (V)"]
        uac(t), [description = "AC voltage magnitude (pu)"]
        pred(t), [description = "FRT prediction input"]
        vdcin(t), [description = "DC voltage (V)"]
        id_ref(t), [description = "d-axis current reference (pu)"]
        iq_ref(t), [description = "q-axis current reference (pu)"]
    end
    eqs = Equation[
        vdcref ~ MPP_delay.u,                                # connect(vdcref, MPP_delay.u)
        uac ~ voltage_measurement_delay.u,                   # connect(uac, voltage_measurement_delay.u)
        voltage_measurement_delay.y ~ feedback.u1,           # connect(voltage_measurement_delay.y, feedback.u1)
        reference_voltage.y ~ feedback.u2,                   # connect(reference_voltage.y, feedback.u2)
        vdcin ~ feedback1.u1,                                # connect(vdcin, feedback1.u1)
        feedback1.y ~ filter.u,                              # connect(feedback1.y, filter.u)
        filter.y ~ activePowerController.yi,                 # connect(filter.y, activePowerController.yi)
        MPP_delay.y ~ limiter.u,                             # connect(MPP_delay.y, limiter.u)
        limiter.y ~ feedback1.u2,                            # connect(limiter.y, feedback1.u2)
        feedback.y ~ reactivePowerSupport.duac,              # connect(feedback.y, reactivePowerSupport.duac)
        current_limiter.iqout ~ iq_ref,                      # connect(current_limiter.iqout, iq_ref)
        current_limiter.idout ~ id_ref,                      # connect(current_limiter.idout, id_ref)
        reactivePowerSupport.iq ~ current_limiter.iqin,      # connect(reactivePowerSupport.iq, current_limiter.iqin)
        current_limiter.duac ~ feedback.y,                   # connect(current_limiter.duac, feedback.y)
        activePowerController.yo ~ current_limiter.idin,     # connect(activePowerController.yo, current_limiter.idin)
        activePowerController.pred ~ pred,                   # connect(activePowerController.pred, pred)
    ]
    System(eqs, t, vars, pars; name, systems)
end
