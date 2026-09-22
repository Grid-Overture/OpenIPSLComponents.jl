# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Solar/PowerFactory/DIgSILENT/PV_Plant.mo (extends Electrical/Essentials/pfComponent.mo:
# enablefn = enableS_b = enableangle_0 = enablev_0 = enableP_0 = enableQ_0 = true; V_b accepted and inert)
# Blocks, with the names of the .mo: controller = DIgSILENT_Controller(..., Tr = Trm, id0 = P_0/M_b/v_0, iq0 =
# -Q_0/M_b/v_0, uac0 = v_0), not_implemented_FRT = Constant(1) -> pred, busbar = DCBusBar(C), generator =
# ElmGenstat(M_b, angle_0, v_0), pu_to_W = Gain(S_b) (generator.P in pu of S_b -> W -> busbar.P_conv), pv_array =
# PVArray(..., P_init = P_0, Tr, use_input_E = use_input_theta = false). `S_b`, `fn` reach the children as
# keyword arguments. `M_b` has no default; the 25 plant parameters keep the defaults of the .mo.
# Julia-only, without changing an equation (PLAN-08, decision "DIgSILENT"): the DC bus of the array has **two
# close regime roots** (the I-V curve is fitted through (Umpp, Impp) and U0 only, its maximum-power point is not
# exactly at Umpp), and OpenModelica converges to the quiescent one, `Udc(0) = n_series*Umpp(E0) = Vmpp_array`.
# The constructor computes `E0` (the irradiance of `P_0`, as PVModule does) and `Udc0 = n_series*Umpp(E0)` and
# hands `Udc0` to the initialization as the guess of `busbar.Udc` and of every alias of it (the .mo's own guess is
# `eps` on `integrator.y`; a guess on an alias `mtkcompile` eliminates is dropped, F-75), which only changes the
# path of Newton, not the equations. Omitted: displayPF, graphical annotations.

@component function PV_Plant(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        M_b, n_series = 20, n_parallel = 140, Tr = 0.01, U0_stc = 43.8, Umpp_stc = 35, Impp_stc = 4.58, Isc_stc = 5,
        au = -0.0039, ai = 0.0004, C = 1.5e-3, Kp = 0.005, Tip = 0.03, Trm = 0.001, Tmpp = 5, id_min = 0, id_max = 1,
        U_min = 200, iq_min = -1, iq_max = 1, Deadband = 0.1, K_FRT = 2, i_EEG = false, maxAbsCur = 1, maxIq = 1)
    S_b, V_b, fn, P_0, Q_0, v_0, angle_0, M_b = float.((S_b, V_b, fn, P_0, Q_0, v_0, angle_0, M_b))
    n_series, n_parallel, Tr, U0_stc, Umpp_stc, Impp_stc, Isc_stc, au, ai, C, Kp, Tip, Trm, Tmpp =
        float.((n_series, n_parallel, Tr, U0_stc, Umpp_stc, Impp_stc, Isc_stc, au, ai, C, Kp, Tip, Trm, Tmpp))
    id_min, id_max, U_min, iq_min, iq_max, Deadband, K_FRT, maxAbsCur, maxIq =
        float.((id_min, id_max, U_min, iq_min, iq_max, Deadband, K_FRT, maxAbsCur, maxIq))
    # the quiescent DC-bus root (see the header): E0 of the module at P_0/(n_parallel*n_series), Udc0 = n_series*Umpp(E0)
    E0 = pvmodule_E0(P_0 / (n_parallel * n_series), Umpp_stc, Impp_stc, 1000.0, 298.15, au, ai)
    Udc0 = n_series * Umpp_stc * log(E0) / log(1000.0)
    base = pfComponent(; name, S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    systems = @named begin
        p = PwPin()
        controller = DIgSILENT_Controller(; Deadband, K_FRT, Kp, Tip, Tmpp, Tr = Trm, U_min, i_EEG, id0 = P_0 / M_b / v_0,
            id_max, id_min, iq0 = -Q_0 / M_b / v_0, iq_max, iq_min, maxAbsCur, maxIq, uac0 = v_0)
        not_implemented_FRT = OpenIPSLComponents.Constant(; k = 1)
        busbar = DCBusBar(; C)
        generator = ElmGenstat(; S_b, fn, M_b, angle_0, v_0)
        pu_to_W = Gain(; k = S_b)
        pv_array = PVArray(; Impp_stc, Isc_stc, P_init = P_0, Tr, U0_stc, Umpp_stc, ai, au, n_parallel, n_series,
            use_input_E = false, use_input_theta = false)
    end
    pars = @parameters begin
        M_b = M_b, [description = "PV plant base power (VA)"]
        n_series = n_series, [description = "Number of modules in series"]
        n_parallel = n_parallel, [description = "Number of modules in parallel"]
        Tr = Tr, [description = "Time constant of modules (s)"]
        U0_stc = U0_stc, [description = "Open-circuit voltage at Standard Test Conditions (V)"]
        Umpp_stc = Umpp_stc, [description = "MPP voltage at Standard Test Conditions (V)"]
        Impp_stc = Impp_stc, [description = "MPP current at Standard Test Conditions (A)"]
        Isc_stc = Isc_stc, [description = "Short-circuit current at Standard Test Conditions (A)"]
        au = au, [description = "Temperature correction factor (voltage) (1/K)"]
        ai = ai, [description = "Temperature correction factor (current) (1/K)"]
        C = C, [description = "Capacity of capacitor on DC busbar (F)"]
        Kp = Kp, [description = "Gain, Active Power PI-Controller"]
        Tip = Tip, [description = "Integration Time Constant, Active Power PI-Ctrl. (s)"]
        Trm = Trm, [description = "Measurement Delay (s)"]
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
    end
    eqs = Equation[
        connect(generator.p, p),
        pu_to_W.u ~ generator.P,                     # connect(pu_to_W.u, generator.P)
        controller.id_ref ~ generator.id_ref,        # connect(controller.id_ref, generator.id_ref)
        controller.iq_ref ~ generator.iq_ref,        # connect(controller.iq_ref, generator.iq_ref)
        controller.uac ~ generator.v,                # connect(controller.uac, generator.v)
        not_implemented_FRT.y ~ controller.pred,     # connect(not_implemented_FRT.y, controller.pred)
        busbar.I_pv ~ pv_array.Iarray,               # connect(busbar.I_pv, pv_array.Iarray)
        pu_to_W.y ~ busbar.P_conv,                   # connect(pu_to_W.y, busbar.P_conv)
        busbar.Udc ~ controller.vdcin,               # connect(busbar.Udc, controller.vdcin)
        busbar.Udc ~ pv_array.Uarray,                # connect(busbar.Udc, pv_array.Uarray)
        pv_array.Vmpp_array ~ controller.vdcref,     # connect(pv_array.Vmpp_array, controller.vdcref)
    ]
    # Udc0 on every alias of the DC voltage (`mtkcompile` keeps `busbar.Udc` as the state and drops a guess given to
    # the alias `integrator.y`, from which Newton then starts at 0 and runs to the open-circuit root at 1e14 V, F-75)
    guesses = Dict(busbar.integrator.y => Udc0, busbar.Udc => Udc0, busbar.P_to_I.u2 => Udc0, pv_array.Uarray => Udc0,
        pv_array.module_time.y => Udc0, pv_array.module_.U => Udc0 / n_series, controller.vdcin => Udc0,
        controller.vdcref => Udc0, controller.MPP_delay.y => Udc0, controller.limiter.y => Udc0, controller.filter.y => 0.0)
    extend(System(eqs, t, [], pars; name, systems, guesses), base)
end
