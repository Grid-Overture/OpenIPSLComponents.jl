# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Wind/GE/Type_3/Electrical_Control/Electrical_Control.mo (extends nothing)
# Blocks, with the names of the .mo: division1 = Pord/Vterm, limiter1 = Limiter(uMax = 1.1, uMin = -inf) -> Ipcmd
# (no low-voltage guard: it saturates at 1.1 during a fault), limiter2 = Limiter(qmax, qmin) on Qord, add1(k1 = -1)
# = limiter2.y - Qgen, limIntegrator1 = LimIntegrator(k = KQi, y_start = ex_x0_0, outMax = 99999, outMin = -99999),
# add2(k2 = -1) = . - Vterm, gain1 = Gain(KVi), lim_exc_s11 = lim_exc_s1(typpe = 1), integrator1 = Integrator(
# y_start = ex_x1_0), lim_exc_s12 = lim_exc_s1(typpe = 2) -> Efd, const = Constant(0) (instance `const_`) feeding
# `lim_exc_s12.Efd`, which `typpe = 2` never reads (a dead input, instantiated all the same). Ports are plain
# variables (Qgen, Qord, Pord, Vterm; Ipcmd, Efd). Omitted: the `import`, graphical annotations.

@component function Electrical_Control(; name, qmax = 1, qmin = 0, KQi = 1, ex_x0_0 = 1, ex_x1_0 = 1, KVi = 1,
        xiqmax = 1, xiqmin = 1)
    qmax, qmin, KQi, ex_x0_0, ex_x1_0, KVi, xiqmax, xiqmin = float.((qmax, qmin, KQi, ex_x0_0, ex_x1_0, KVi, xiqmax, xiqmin))
    inf = Modelica.Constants.inf
    systems = @named begin
        division1 = Division()
        limiter1 = Limiter(; uMax = 1.1, uMin = -inf)
        limiter2 = Limiter(; uMax = qmax, uMin = qmin)
        add1 = Add(; k1 = -1)
        limIntegrator1 = LimIntegrator(; k = KQi, y_start = ex_x0_0, outMax = 99999, outMin = -99999)
        add2 = Add(; k2 = -1)
        gain1 = Gain(; k = KVi)
        lim_exc_s11 = lim_exc_s1(; typpe = 1, xiqmax, xiqmin)
        lim_exc_s12 = lim_exc_s1(; typpe = 2, xiqmax, xiqmin)
        integrator1 = Integrator(; y_start = ex_x1_0)
        const_ = OpenIPSLComponents.Constant(; k = 0)
    end
    pars = @parameters begin
        qmax = qmax
        qmin = qmin
        KQi = KQi
        ex_x0_0 = ex_x0_0
        ex_x1_0 = ex_x1_0
        KVi = KVi
        xiqmax = xiqmax
        xiqmin = xiqmin
    end
    vars = @variables begin
        Qgen(t), [description = "Reactive Power produced by the Generator"]
        Qord(t), [description = "Reactive power command"]
        Pord(t), [description = "Active power command"]
        Vterm(t), [description = "Terminal voltage"]
        Ipcmd(t), [description = "Current command"]
        Efd(t), [description = "Excitation voltage"]
    end
    eqs = Equation[
        const_.y ~ lim_exc_s12.Efd,              # connect(const.y, lim_exc_s12.Efd)
        integrator1.y ~ lim_exc_s12.Vref,        # connect(integrator1.y, lim_exc_s12.Vref)
        lim_exc_s11.Efd ~ lim_exc_s12.y,         # connect(lim_exc_s11.Efd, lim_exc_s12.y)
        lim_exc_s12.Vt ~ Vterm,                  # connect(lim_exc_s12.Vt, Vterm)
        lim_exc_s12.y ~ Efd,                     # connect(lim_exc_s12.y, Efd)
        gain1.y ~ lim_exc_s11.Vref,              # connect(gain1.y, lim_exc_s11.Vref)
        lim_exc_s11.y ~ integrator1.u,           # connect(lim_exc_s11.y, integrator1.u)
        lim_exc_s11.Vt ~ Vterm,                  # connect(lim_exc_s11.Vt, Vterm)
        Qgen ~ add1.u1,                          # connect(Qgen, add1.u1)
        Qord ~ limiter2.u,                       # connect(Qord, limiter2.u)
        limiter1.y ~ Ipcmd,                      # connect(limiter1.y, Ipcmd)
        Vterm ~ division1.u2,                    # connect(Vterm, division1.u2)
        add2.u2 ~ Vterm,                         # connect(add2.u2, Vterm)
        Pord ~ division1.u1,                     # connect(Pord, division1.u1)
        add2.y ~ gain1.u,                        # connect(add2.y, gain1.u)
        limIntegrator1.y ~ add2.u1,              # connect(limIntegrator1.y, add2.u1)
        add1.y ~ limIntegrator1.u,               # connect(add1.y, limIntegrator1.u)
        limiter2.y ~ add1.u2,                    # connect(limiter2.y, add1.u2)
        division1.y ~ limiter1.u,                # connect(division1.y, limiter1.u)
    ]
    System(eqs, t, vars, pars; name, systems)
end
