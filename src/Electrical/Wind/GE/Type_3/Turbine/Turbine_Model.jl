# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Wind/GE/Type_3/Turbine/Turbine_Model.mo (extends nothing)
# Blocks, with the names of the .mo: rotor_Model1 = Rotor_Model, wind_Power_Model1 = Wind_Power_Model(KI, wndtge_kp),
# Change_Base = Gain(GEN_base/WT_base), add1(k2 = -1), integrator1 = Integrator(1/5, wt_x5_0) (the speed
# reference), add2(k1 = -1), the pitch loop Gain_Kpp, integrator2 = Integrator(Kip, wt_x1_0), add31, integrator3 =
# Integrator(Kic, wt_x3_0), add3, Gain_Kpc, add4(k1 = -1), add5(k2 = -1), Gain_iTP = Gain(1/Tp), limiter1 =
# Limiter(uMax = pirat) (uMin = -pirat, MSL's default), limIntegrator1 = LimIntegrator(pimax, pimin, wt_x0_0,
# InitialOutput) = the pitch, the torque loop Gain_Kptrq, integrator4 = Integrator(Kitrq, wt_x2_0), add6, product1,
# add8(k2 = -1), Gain_iTPc = Gain(1/Tpc), limiter2 = Limiter(uMax = pwrat), limIntegrator2 = LimIntegrator(pwmax,
# pwmin, wt_x4_0), Change_Base1 = Gain(WT_base/GEN_base) -> Pord, const = Constant(1) (instance `const_`). Ports
# are plain variables (Pelec, Wind_Speed; Pord). Every `Integrator` is InitialState (MSL's default) and the pitch
# integrator InitialOutput, as in the .mo.
# `add1.u1 = if Change_Base.y >= 0.75 then 1.2 else ...` is on a variable -> `ifelse`. `thlim1`, `pwlim2` are the
# two protected Booleans (0/1 algebraic variables, `ifelse` without event, precedent `Voltage_dip`): `thlim1 = not
# (limIntegrator1.y <= pimin + eps and limiter1.y < 0)` freezes the pitch integrators only at `pimin`, `pwlim2`
# freezes the torque integrator only at `pwmax` (asymmetric, sic). Omitted: graphical annotations.

@component function Turbine_Model(; name, GEN_base = 1e6, WT_base = 1e6, Kpp = 1, Kip = 1, pirat = 1, pimax = 1,
        pimin = 1, pwrat = 1, pwmax = 1, pwmin = 1, Kic = 1, Kpc = 1, Tp = 1, Tpc = 1, Kptrq = 1, Kitrq = 1, Dtg = 1,
        H = 1, Hg = 1, Ktg = 1, KI = 1, wndtge_kp = 1, wt_x0_0 = 1, wt_x1_0 = 1, wt_x2_0 = 1, wt_x3_0 = 1, wt_x4_0 = 1,
        wt_x5_0 = 1, wt_x6_0 = 1, wt_x7_0 = 1, wt_x8_0 = 1, wt_x9_0 = 1, wbase = 1, wndtge_ang0 = 1, wndtge_spd0 = 1)
    GEN_base, WT_base, Kpp, Kip, pirat, pimax, pimin, pwrat, pwmax, pwmin, Kic, Kpc, Tp, Tpc, Kptrq, Kitrq =
        float.((GEN_base, WT_base, Kpp, Kip, pirat, pimax, pimin, pwrat, pwmax, pwmin, Kic, Kpc, Tp, Tpc, Kptrq, Kitrq))
    Dtg, H, Hg, Ktg, KI, wndtge_kp, wbase, wndtge_ang0, wndtge_spd0 =
        float.((Dtg, H, Hg, Ktg, KI, wndtge_kp, wbase, wndtge_ang0, wndtge_spd0))
    wt_x0_0, wt_x1_0, wt_x2_0, wt_x3_0, wt_x4_0, wt_x5_0, wt_x6_0, wt_x7_0, wt_x8_0, wt_x9_0 =
        float.((wt_x0_0, wt_x1_0, wt_x2_0, wt_x3_0, wt_x4_0, wt_x5_0, wt_x6_0, wt_x7_0, wt_x8_0, wt_x9_0))
    eps = Modelica.Constants.eps
    systems = @named begin
        rotor_Model1 = Rotor_Model(; wt_x6_0, wt_x7_0, wt_x8_0, wt_x9_0, Dtg, H, Hg, Ktg, wbase, wndtge_ang0, wndtge_spd0)
        wind_Power_Model1 = Wind_Power_Model(; KI, wndtge_kp)
        Change_Base = Gain(; k = GEN_base / WT_base)
        add1 = Add(; k2 = -1)
        integrator1 = Integrator(; k = 1 / 5, y_start = wt_x5_0)
        add2 = Add(; k1 = -1)
        Gain_Kpp = Gain(; k = Kpp)
        integrator2 = Integrator(; k = Kip, y_start = wt_x1_0)
        add31 = Add3()
        integrator3 = Integrator(; k = Kic, y_start = wt_x3_0)
        add3 = Add()
        Gain_Kpc = Gain(; k = Kpc)
        add4 = Add(; k1 = -1)
        add5 = Add(; k2 = -1)
        Gain_iTP = Gain(; k = 1 / Tp)
        limiter1 = Limiter(; uMax = pirat)
        limIntegrator1 = LimIntegrator(; y_start = wt_x0_0, outMax = pimax, outMin = pimin, initType = :InitialOutput)
        Gain_Kptrq = Gain(; k = Kptrq)
        add6 = Add()
        integrator4 = Integrator(; k = Kitrq, y_start = wt_x2_0)
        product1 = Product()
        limIntegrator2 = LimIntegrator(; outMax = pwmax, outMin = pwmin, y_start = wt_x4_0)
        limiter2 = Limiter(; uMax = pwrat)
        Gain_iTPc = Gain(; k = 1 / Tpc)
        add8 = Add(; k2 = -1)
        Change_Base1 = Gain(; k = WT_base / GEN_base)
        const_ = OpenIPSLComponents.Constant(; k = 1)
    end
    pars = @parameters begin
        GEN_base = GEN_base, [description = "Base Power from the Electrical Generator (VA)"]
        WT_base = WT_base, [description = "Base Power from the Turbine (VA)"]
        Kpp = Kpp
        Kip = Kip
        pirat = pirat
        pimax = pimax
        pimin = pimin
        pwrat = pwrat
        pwmax = pwmax
        pwmin = pwmin
        Kic = Kic
        Kpc = Kpc
        Tp = Tp
        Tpc = Tpc
        Kptrq = Kptrq
        Kitrq = Kitrq
    end
    vars = @variables begin
        Pelec(t), [description = "Electrical power"]
        Wind_Speed(t), [description = "Wind speed"]
        Pord(t), [description = "Active power command"]
        thlim1(t), [description = "Boolean (0/1): pitch integrators active"]
        pwlim2(t), [description = "Boolean (0/1): torque integrator active"]
    end
    eqs = Equation[
        Pelec ~ Change_Base.u,                                   # connect(Pelec, Change_Base.u)
        Wind_Speed ~ wind_Power_Model1.Wind_Speed,               # connect(Wind_Speed, wind_Power_Model1.Wind_Speed)
        integrator1.y ~ add2.u1,                                 # connect(integrator1.y, add2.u1)
        add1.u2 ~ integrator1.y,                                 # connect(add1.u2, integrator1.y)
        add1.y ~ integrator1.u,                                  # connect(add1.y, integrator1.u)
        Change_Base1.y ~ Pord,                                   # connect(Change_Base1.y, Pord)
        const_.y ~ add4.u1,                                      # connect(const.y, add4.u1)
        add4.u2 ~ limIntegrator2.y,                              # connect(add4.u2, limIntegrator2.y)
        limIntegrator2.y ~ Change_Base1.u,                       # connect(limIntegrator2.y, Change_Base1.u)
        add8.y ~ Gain_iTPc.u,                                    # connect(add8.y, Gain_iTPc.u)
        add5.y ~ Gain_iTP.u,                                     # connect(add5.y, Gain_iTP.u)
        Gain_iTPc.y ~ limiter2.u,                                # connect(Gain_iTPc.y, limiter2.u)
        product1.y ~ add8.u1,                                    # connect(product1.y, add8.u1)
        limIntegrator2.y ~ add8.u2,                              # connect(limIntegrator2.y, add8.u2)
        limiter2.y ~ limIntegrator2.u,                           # connect(limiter2.y, limIntegrator2.u)
        integrator4.y ~ add6.u2,                                 # connect(integrator4.y, add6.u2)
        add31.u2 ~ integrator2.y,                                # connect(add31.u2, integrator2.y)
        add3.y ~ add31.u3,                                       # connect(add3.y, add31.u3)
        add2.y ~ Gain_Kptrq.u,                                   # connect(add2.y, Gain_Kptrq.u)
        rotor_Model1.omega_gen ~ product1.u1,                    # connect(rotor_Model1.omega_gen, product1.u1)
        add6.y ~ product1.u2,                                    # connect(add6.y, product1.u2)
        Gain_Kptrq.y ~ add6.u1,                                  # connect(Gain_Kptrq.y, add6.u1)
        wind_Power_Model1.Theta ~ limIntegrator1.y,              # connect(wind_Power_Model1.Theta, limIntegrator1.y)
        limIntegrator1.y ~ add5.u2,                              # connect(limIntegrator1.y, add5.u2)
        limiter1.y ~ limIntegrator1.u,                           # connect(limiter1.y, limIntegrator1.u)
        Gain_iTP.y ~ limiter1.u,                                 # connect(Gain_iTP.y, limiter1.u)
        add31.y ~ add5.u1,                                       # connect(add31.y, add5.u1)
        integrator3.y ~ add3.u2,                                 # connect(integrator3.y, add3.u2)
        add4.y ~ Gain_Kpc.u,                                     # connect(add4.y, Gain_Kpc.u)
        Gain_Kpc.y ~ add3.u1,                                    # connect(Gain_Kpc.y, add3.u1)
        Gain_Kpp.y ~ add31.u1,                                   # connect(Gain_Kpp.y, add31.u1)
        add2.y ~ Gain_Kpp.u,                                     # connect(add2.y, Gain_Kpp.u)
        Change_Base.y ~ rotor_Model1.Pe,                         # connect(Change_Base.y, rotor_Model1.Pe)
        rotor_Model1.omega_gen ~ add2.u2,                        # connect(rotor_Model1.omega_gen, add2.u2)
        wind_Power_Model1.Pm ~ rotor_Model1.Pm,                  # connect(wind_Power_Model1.Pm, rotor_Model1.Pm)
        rotor_Model1.omega_turb ~ wind_Power_Model1.omega,       # connect(rotor_Model1.omega_turb, wind_Power_Model1.omega)
        add1.u1 ~ ifelse(Change_Base.y >= 0.75, 1.2, ((-0.67 * Change_Base.y) + 1.42) * Change_Base.y + 0.51),
        integrator2.u ~ ifelse(thlim1 > 0.5, add2.y, 0),
        integrator3.u ~ ifelse(thlim1 > 0.5, add4.y, 0),
        integrator4.u ~ ifelse(pwlim2 > 0.5, add2.y, 0),
        thlim1 ~ ifelse((limIntegrator1.y <= pimin + eps) & (limiter1.y < 0), 0, 1),   # not (... and ...)
        pwlim2 ~ ifelse((limIntegrator2.y >= pwmax) & (limiter2.y > 0), 0, 1),         # not (... and ...)
    ]
    System(eqs, t, vars, pars; name, systems)
end
