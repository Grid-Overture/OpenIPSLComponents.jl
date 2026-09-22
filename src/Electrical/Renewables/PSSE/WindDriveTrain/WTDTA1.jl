# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Renewables/PSSE/WindDriveTrain/WTDTA1.mo (extends BaseClasses/BaseWTDT.mo)
# The two-mass drive train of a type 3/4 wind turbine. Derived parameters in dependency order:
#   Ht = H*Htfrac,  Hg = H - Ht,  w0 = 2*pi*fn,  Kshaft = 2*Ht*Hg*(2*pi*Freq1)^2/(H*w0).
# `T0` is a `parameter (fixed = false)` whose `initial equation` reads the *input* `P0` -> F-33 (`guess` +
# `initial_conditions => missing` + `initialization_eqs`), and `integrator2(k = Kshaft, y_start = T0)` receives the
# symbol (F-38).
# The four integrators: `integrator(k = 1/(2Ht), y_start = W0)` is the turbine speed `wt`; `integrator1(k = 1/(2Hg),
# y_start = W0)` is the generator speed **deviation** (`wg = add4.y = 1 + integrator1.y`); `integrator2` is the shaft
# torque; `integrator3(k = 1, y_start = 0)` is the shaft angle, a state whose output feeds nothing -- it is kept,
# and `mtkcompile` keeps it as an unobserved state.
# `const` and `const1` are Julia keywords in the first case, so both are suffixed (`const_`, `const1`) as elsewhere
# in the port; no oracle column refers to them by a name that clashes.
# `division = Pm/(1 + wt)` and `division1 = Pe/(1 + integrator1.y)` are the two torque conversions.
# Omitted: Icons.VerifiedModel, graphical annotations.

@component function WTDTA1(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        W0 = 0, H = 5.3, DAMP = 0, Htfrac = 0.92, Freq1 = 2.132, Dshaft = 1)
    S_b, fn, W0, H, DAMP, Htfrac, Freq1, Dshaft = float.((S_b, fn, W0, H, DAMP, Htfrac, Freq1, Dshaft))
    Ht = H * Htfrac
    Hg = H - Ht
    w0 = 2 * pi * fn
    Kshaft = 2 * Ht * Hg * (2 * pi * Freq1)^2 / (H * w0)
    base = BaseWTDT(; name, S_b, V_b, fn, P_0, Q_0, v_0, angle_0, W0)
    @unpack Pm, Pe, wt, wg, W_0, P0 = base
    pars = @parameters begin
        H = H, [description = "Total inertia constant (s)"]
        DAMP = DAMP, [description = "Machine damping factor"]
        Htfrac = Htfrac, [description = "Turbine inertia fraction, Ht/H"]
        Freq1 = Freq1, [description = "First shaft torsional resonancy frequency (Hz)"]
        Dshaft = Dshaft, [description = "Shaft damping factor"]
        T0, [guess = 1.0]
    end
    systems = @named begin
        Coef1 = Gain(; k = Dshaft)
        integrator = Integrator(; k = 1 / (2 * Ht), initType = :InitialState, y_start = W0)
        integrator1 = Integrator(; k = 1 / (2 * Hg), initType = :InitialState, y_start = W0)
        Coef2 = Gain(; k = DAMP)
        add = Add(; k2 = -1)
        add3_1 = Add3(; k1 = -1, k3 = -1)
        realExpression = RealExpression(; expr = nothing)    # y = add.y (F-22)
        add1 = Add(; k1 = -1)
        w0__ = Gain(; k = w0)
        add2 = Add(; k1 = -1)
        add3_2 = Add3(; k1 = 1, k2 = -1, k3 = 1)
        realExpression1 = RealExpression(; expr = nothing)   # y = integrator2.y
        integrator2 = Integrator(; k = Kshaft, initType = :InitialState, y_start = T0)
        realExpression2 = RealExpression(; expr = nothing)   # y = integrator2.y
        w0_ = Gain(; k = w0)
        integrator3 = Integrator(; k = 1, initType = :InitialState, y_start = 0)
        division = Division()
        add3 = Add(; k2 = 1)
        const_ = OpenIPSLComponents.Constant(; k = 1)        # `const` in the .mo (a Julia keyword)
        add4 = Add(; k2 = 1)
        const1 = OpenIPSLComponents.Constant(; k = 1)
        division1 = Division()
    end
    eqs = Equation[
        realExpression.y ~ add.y,
        realExpression1.y ~ integrator2.y,
        realExpression2.y ~ integrator2.y,
        add3_1.y ~ integrator.u,             # connect(add3_1.y, integrator.u)
        Coef1.u ~ realExpression.y,          # connect(Coef1.u, realExpression.y)
        integrator1.y ~ add.u2,              # connect(integrator1.y, add.u2)
        Coef2.u ~ add.u2,                    # connect(Coef2.u, add.u2)
        Coef2.y ~ add1.u1,                   # connect(Coef2.y, add1.u1)
        add.y ~ w0__.u,                      # connect(add.y, w0__.u)
        add3_2.y ~ add1.u2,                  # connect(add3_2.y, add1.u2)
        Coef1.y ~ add3_1.u1,                 # connect(Coef1.y, add3_1.u1)
        add3_2.u1 ~ add3_1.u1,               # connect(add3_2.u1, add3_1.u1)
        realExpression1.y ~ add3_1.u3,       # connect(realExpression1.y, add3_1.u3)
        w0__.y ~ integrator2.u,              # connect(w0__.y, integrator2.u)
        realExpression2.y ~ add3_2.u3,       # connect(realExpression2.y, add3_2.u3)
        add1.y ~ integrator1.u,              # connect(add1.y, integrator1.u)
        add2.u2 ~ add.u2,                    # connect(add2.u2, add.u2)
        add2.y ~ w0_.u,                      # connect(add2.y, w0_.u)
        w0_.y ~ integrator3.u,               # connect(w0_.y, integrator3.u)
        integrator.y ~ wt,                   # connect(integrator.y, wt)
        add.u1 ~ wt,                         # connect(add.u1, wt)
        division.y ~ add3_1.u2,              # connect(division.y, add3_1.u2)
        Pm ~ division.u1,                    # connect(Pm, division.u1)
        add3.u2 ~ wt,                        # connect(add3.u2, wt)
        const_.y ~ add3.u1,                  # connect(const.y, add3.u1)
        const1.y ~ add4.u1,                  # connect(const1.y, add4.u1)
        add4.u2 ~ add.u2,                    # connect(add4.u2, add.u2)
        add3.y ~ division.u2,                # connect(add3.y, division.u2)
        division1.y ~ add3_2.u2,             # connect(division1.y, add3_2.u2)
        Pe ~ division1.u1,                   # connect(Pe, division1.u1)
        division1.u2 ~ add4.y,               # connect(division1.u2, add4.y)
        wg ~ add4.y,                         # connect(wg, add4.y)
        add2.u1 ~ W_0,                       # connect(add2.u1, W_0)
    ]
    extend(System(eqs, t, [], pars; name, systems,
            initial_conditions = Dict(T0 => missing), initialization_eqs = [T0 ~ P0]), base)
end
