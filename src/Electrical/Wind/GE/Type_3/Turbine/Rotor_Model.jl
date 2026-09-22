# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Wind/GE/Type_3/Turbine/Rotor_Model.mo (extends nothing)
# Blocks, with the names of the .mo: the four `Integrator(y_start = wt_x*_0)` (InitialState, MSL's default):
# integrator1 (1/(2H), wt_x6_0) is the turbine speed deviation, integrator3 (wbase, wt_x7_0) the turbine angle,
# integrator2 (1/(2Hg), wt_x8_0) the generator speed deviation, integrator4 (wbase, wt_x9_0) the generator angle;
# add31, add32(-1, -1, -1), division1 = Pm/omega_turb, division2 = Pe/omega_gen, i2H, Gain_i2Hg, Gain1_wbase,
# Gain_wbase, add1(k1 = -1), Gain_Dtg, add2(k1 = -1), Gain_Ktg, add3, add4, add5, Const1_wndtge_spd0,
# Const_wndtge_spd0, Const_wndtge_ang0 (the two Constants of spd0 are both instantiated, as in the .mo). Ports are
# plain variables (Pm, Pe; omega_gen, omega_turb). The two-mass drive train of WTDTA1 with other names; the sign of
# the damping is literal (+Dtg*(dw_g - dw_t) on the turbine, - on the generator). Omitted: graphical annotations.

@component function Rotor_Model(; name, H = 0.3, Hg = 0.3, wbase = 1, Dtg = 1, Ktg = 1, wt_x6_0 = 1, wt_x7_0 = 1,
        wt_x8_0 = 1, wt_x9_0 = 1, wndtge_ang0 = 1, wndtge_spd0 = 1)
    H, Hg, wbase, Dtg, Ktg, wt_x6_0, wt_x7_0, wt_x8_0, wt_x9_0, wndtge_ang0, wndtge_spd0 =
        float.((H, Hg, wbase, Dtg, Ktg, wt_x6_0, wt_x7_0, wt_x8_0, wt_x9_0, wndtge_ang0, wndtge_spd0))
    systems = @named begin
        integrator1 = Integrator(; y_start = wt_x6_0)
        integrator2 = Integrator(; y_start = wt_x8_0)
        integrator3 = Integrator(; y_start = wt_x7_0)
        integrator4 = Integrator(; y_start = wt_x9_0)
        add31 = Add3()
        division1 = Division()
        division2 = Division()
        add32 = Add3(; k1 = -1, k2 = -1, k3 = -1)
        i2H = Gain(; k = 1 / (2 * H))
        Gain_i2Hg = Gain(; k = 1 / (2 * Hg))
        Gain1_wbase = Gain(; k = wbase)
        Gain_wbase = Gain(; k = wbase)
        add1 = Add(; k1 = -1)
        Gain_Dtg = Gain(; k = Dtg)
        add2 = Add(; k1 = -1)
        Gain_Ktg = Gain(; k = Ktg)
        add3 = Add()
        add4 = Add()
        add5 = Add()
        Const1_wndtge_spd0 = OpenIPSLComponents.Constant(; k = wndtge_spd0)
        Const_wndtge_spd0 = OpenIPSLComponents.Constant(; k = wndtge_spd0)
        Const_wndtge_ang0 = OpenIPSLComponents.Constant(; k = wndtge_ang0)
    end
    pars = @parameters begin
        H = H, [description = "inertia (s)"]
        Hg = Hg, [description = "generator inertia (s)"]
        wbase = wbase
        Dtg = Dtg
        Ktg = Ktg
        wt_x6_0 = wt_x6_0
        wt_x7_0 = wt_x7_0
        wt_x8_0 = wt_x8_0
        wt_x9_0 = wt_x9_0
        wndtge_ang0 = wndtge_ang0
        wndtge_spd0 = wndtge_spd0
    end
    vars = @variables begin
        Pm(t), [description = "Mechanical Power Input"]
        Pe(t), [description = "Electrical Power Input"]
        omega_gen(t), [description = "Engine shaft angular velocity"]
        omega_turb(t), [description = "engine shaft angular velocity"]
    end
    eqs = Equation[
        Const_wndtge_spd0.y ~ add5.u1,           # connect(Const_wndtge_spd0.y, add5.u1)
        Const1_wndtge_spd0.y ~ add4.u2,          # connect(Const1_wndtge_spd0.y, add4.u2)
        omega_gen ~ add4.y,                      # connect(omega_gen, add4.y)
        omega_turb ~ add5.y,                     # connect(omega_turb, add5.y)
        Const_wndtge_ang0.y ~ add3.u1,           # connect(Const_wndtge_ang0.y, add3.u1)
        Pe ~ division2.u1,                       # connect(Pe, division2.u1)
        Pm ~ division1.u1,                       # connect(Pm, division1.u1)
        integrator2.y ~ Gain_wbase.u,            # connect(integrator2.y, Gain_wbase.u)
        Gain_wbase.y ~ integrator4.u,            # connect(Gain_wbase.y, integrator4.u)
        integrator1.y ~ Gain1_wbase.u,           # connect(integrator1.y, Gain1_wbase.u)
        Gain1_wbase.y ~ integrator3.u,           # connect(Gain1_wbase.y, integrator3.u)
        Gain_Ktg.y ~ add31.u1,                   # connect(Gain_Ktg.y, add31.u1)
        Gain_Ktg.y ~ add32.u3,                   # connect(Gain_Ktg.y, add32.u3)
        add2.y ~ Gain_Ktg.u,                     # connect(add2.y, Gain_Ktg.u)
        add32.y ~ Gain_i2Hg.u,                   # connect(add32.y, Gain_i2Hg.u)
        Gain_i2Hg.y ~ integrator2.u,             # connect(Gain_i2Hg.y, integrator2.u)
        add1.y ~ Gain_Dtg.u,                     # connect(add1.y, Gain_Dtg.u)
        Gain_Dtg.y ~ add32.u1,                   # connect(Gain_Dtg.y, add32.u1)
        Gain_Dtg.y ~ add31.u3,                   # connect(Gain_Dtg.y, add31.u3)
        i2H.y ~ integrator1.u,                   # connect(i2H.y, integrator1.u)
        add31.y ~ i2H.u,                         # connect(add31.y, i2H.u)
        integrator2.y ~ add4.u1,                 # connect(integrator2.y, add4.u1)
        add5.u2 ~ integrator1.y,                 # connect(add5.u2, integrator1.y)
        add1.u1 ~ integrator1.y,                 # connect(add1.u1, integrator1.y)
        add1.u2 ~ integrator2.y,                 # connect(add1.u2, integrator2.y)
        add3.u2 ~ integrator4.y,                 # connect(add3.u2, integrator4.y)
        add3.y ~ add2.u2,                        # connect(add3.y, add2.u2)
        integrator3.y ~ add2.u1,                 # connect(integrator3.y, add2.u1)
        division2.u2 ~ add4.y,                   # connect(division2.u2, add4.y)
        division1.u2 ~ add5.y,                   # connect(division1.u2, add5.y)
        division2.y ~ add32.u2,                  # connect(division2.y, add32.u2)
        division1.y ~ add31.u2,                  # connect(division1.y, add31.u2)
    ]
    System(eqs, t, vars, pars; name, systems)
end
