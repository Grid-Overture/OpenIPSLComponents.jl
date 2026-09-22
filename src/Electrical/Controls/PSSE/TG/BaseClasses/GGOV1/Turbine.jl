# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/TG/BaseClasses/GGOV1/Turbine.mo (model)
# Blocks: product/product1 = Product, s4 = LeadLag(1, Tc, Tb, y_start = s40), gain1 = Gain(Kturb),
# add4 = Add(k2 = -1), add5 = Add(k1 = -1), gain2 = Gain(Dm), flag10 = Flag(Flag), dm_select = Dm_select(Dm),
# Tactgain = Gain(1/Tact), V1 = Limiter(Ropen, Rclose), s3 = Integrator(k = 1, InitialOutput, y_start = s30),
# add8 = Add(k2 = -1), s5 = SimpleLag(1, Tfload, y_start = s50), s9 = LeadLag(1, Tsa, Tsb, y_start = s90),
# const = Constant(Wfnl) (instance `const_`), Dw2w = Add, const1 = Constant(1), limiter = Limiter(Vmax, Vmin),
# fixedDelay = FixedDelay(Teng). Ports as plain variables: SPEED, FSR, PELEC (inputs), PMECH, TEXM, VSTROKE
# (outputs).
# `delay` (the `Types.DelayType` of the .mo) is a Symbol keyword and only `:FixedDelay` is accepted: the `.mo`'s
# `padeDelay` instance is conditional on `delay == PadeDelay` and carries `delayTime = C.eps` (sic - it ignores
# `Teng`), and no Test or Example of OpenIPSL 3.1.0 selects it, so that branch is not reproduced (rule 6, "nothing
# just in case"). `pade` is the Julia-only keyword of `FixedDelay` (F-51), not the `.mo`'s `delay`.
# Six `fixed = false` parameters from the input PELEC, in the .mo's order: `Pmech0`, `s30`, `s40`, `s50`, `s90`,
# `fsr0` (note `s50 = s90` and `s90 = fsr0`), as `missing` parameters with their equations in `initialization_eqs`
# (F-33), reaching `s3`, `s4`, `s5` and `s9` symbolically (F-38).
# Julia-only name: the class is `Turbine` in the `.mo`, as `BaseClasses.WEHGOV.Turbine` is, and the package module
# is flat, so this one is `GGOV1_Turbine` (the name table); the instance `GGOV1.mo` builds is still
# `gGOV1_Turb`, so no hierarchical name changes.
# Omitted: graphical annotations.

@component function GGOV1_Turbine(; name, Flag = 1, delay = :FixedDelay, Tact = 0.5, Kturb = 1.5, Tb = 0.1, Tc = 0,
        Teng = 0, Tfload = 3, Dm = 0, Vmax = 1, Vmin = 0.15, Ropen = 0.1, Rclose = -0.1, Tsa = 4, Tsb = 5,
        DELT = 0.005, Wfnl = 0.2, pade = 0)
    delay === :FixedDelay ||
        error("Turbine: only delay = :FixedDelay is ported; the .mo's PadeDelay branch carries delayTime = C.eps " *
              "and no Test or Example selects it (PLAN-05)")
    Flagn = Flag   # the Integer value: `@parameters` below rebinds `Flag` to the symbol (F-22)
    Tact, Kturb, Tb, Tc, Teng, Tfload, Dm, Vmax, Vmin, Ropen, Rclose, Tsa, Tsb, DELT, Wfnl =
        float.((Tact, Kturb, Tb, Tc, Teng, Tfload, Dm, Vmax, Vmin, Ropen, Rclose, Tsa, Tsb, DELT, Wfnl))
    n = (; Tact, Kturb, Tb, Tc, Teng, Tfload, Dm, Vmax, Vmin, Ropen, Rclose, Tsa, Tsb, DELT, Wfnl)
    pars = @parameters begin
        Flag = Flag, [description = "Switch for fuel source characteristic"]
        Tact = Tact, [description = "Actuator time constant"]
        Kturb = Kturb, [description = "Turbine gain"]
        Tb = Tb, [description = "Turbine lag time constant"]
        Tc = Tc, [description = "Turbine lead time constant"]
        Teng = Teng, [description = "Transport lag time constant for diesel engine"]
        Tfload = Tfload, [description = "Load Limiter time constant"]
        Dm = Dm, [description = "Mechanical damping coefficient"]
        Vmax = Vmax, [description = "Maximum valve position limit"]
        Vmin = Vmin, [description = "Minimum valve position limit"]
        Ropen = Ropen, [description = "Maximum valve opening rate"]
        Rclose = Rclose, [description = "Maximum valve closing rate"]
        Tsa = Tsa, [description = "Temperature detection lead time constant"]
        Tsb = Tsb, [description = "Temperature detection lag time constant"]
        DELT = DELT, [description = "Time step used in simulation"]
        Wfnl = Wfnl, [description = "No load fuel flow"]
        Pmech0, [guess = 1.0]
        s30, [guess = 1.0]
        s40, [guess = 1.0]
        s50, [guess = 1.0]
        s90, [guess = 1.0]
        fsr0, [guess = 1.0]
    end
    systems = @named begin
        product = Product()
        s4 = LeadLag(; K = 1, T1 = n.Tc, T2 = n.Tb, y_start = s40)
        gain1 = Gain(; k = n.Kturb)
        add4 = Add(; k2 = -1)
        add5 = Add(; k1 = -1)
        gain2 = Gain(; k = n.Dm)
        flag10 = GGOV1_Flag(; Flag = Flagn)
        dm_select = Dm_select(; Dm = n.Dm)
        Tactgain = Gain(; k = 1 / n.Tact)
        V1 = Limiter(; uMax = n.Ropen, uMin = n.Rclose)
        s3 = Integrator(; k = 1, initType = :InitialOutput, y_start = s30)
        add8 = Add(; k2 = -1)
        s5 = SimpleLag(; T = n.Tfload, y_start = s50, K = 1)
        s9 = LeadLag(; T1 = n.Tsa, T2 = n.Tsb, y_start = s90, K = 1)
        product1 = Product()
        const_ = Constant(; k = n.Wfnl)
        Dw2w = Add()
        const1 = Constant(; k = 1)
        limiter = Limiter(; uMax = n.Vmax, uMin = n.Vmin)
        fixedDelay = FixedDelay(; delayTime = n.Teng, pade)
    end
    vars = @variables begin
        SPEED(t), [description = "Machine speed deviation from nominal (pu)"]
        FSR(t), [description = "Governor Output"]
        PMECH(t), [description = "Turbine mechanical power (pu)"]
        TEXM(t), [description = "Measured Exhaust Temperature"]
        VSTROKE(t), [description = "Valve Position"]
        PELEC(t), [description = "Machine electrical power (pu)"]
    end
    eqs = Equation[
        s4.y ~ add5.u2,                 # connect(s4.y, add5.u2)
        product.y ~ add4.u1,            # connect(product.y, add4.u1)
        gain2.y ~ add5.u1,              # connect(gain2.y, add5.u1)
        dm_select.y ~ gain2.u,          # connect(dm_select.y, gain2.u)
        V1.y ~ s3.u,                    # connect(V1.y, s3.u)
        Tactgain.y ~ V1.u,              # connect(Tactgain.y, V1.u)
        add8.y ~ Tactgain.u,            # connect(add8.y, Tactgain.u)
        add5.y ~ PMECH,                 # connect(add5.y, PMECH)
        s5.u ~ s9.y,                    # connect(s5.u, s9.y)
        product1.u2 ~ gain2.u,          # connect(product1.u2, gain2.u)
        product1.u1 ~ add4.u1,          # connect(product1.u1, add4.u1)
        s9.u ~ product1.y,              # connect(s9.u, product1.y)
        s5.y ~ TEXM,                    # connect(s5.y, TEXM)
        const_.y ~ add4.u2,             # connect(const.y, add4.u2)
        Dw2w.y ~ dm_select.speed,       # connect(Dw2w.y, dm_select.speed)
        flag10.speed ~ dm_select.speed, # connect(flag10.speed, dm_select.speed)
        add4.y ~ gain1.u,               # connect(add4.y, gain1.u)
        flag10.y ~ product.u1,          # connect(flag10.y, product.u1)
        limiter.y ~ product.u2,         # connect(limiter.y, product.u2)
        VSTROKE ~ limiter.y,            # connect(VSTROKE, limiter.y)
        add8.u2 ~ limiter.y,            # connect(add8.u2, limiter.y)
        s3.y ~ limiter.u,               # connect(s3.y, limiter.u)
        const1.y ~ Dw2w.u2,             # connect(const1.y, Dw2w.u2)
        SPEED ~ Dw2w.u1,                # connect(SPEED, Dw2w.u1)
        FSR ~ add8.u1,                  # connect(FSR, add8.u1)
        fixedDelay.y ~ s4.u,            # connect(fixedDelay.y, s4.u)
        gain1.y ~ fixedDelay.u,         # connect(gain1.y, fixedDelay.u)
    ]
    ieqs = [Pmech0 ~ PELEC, s30 ~ fsr0, s40 ~ Pmech0, s50 ~ s90, s90 ~ fsr0, fsr0 ~ (Pmech0 + Dm) / Kturb + Wfnl]
    System(eqs, t, vars, pars; name, systems, initialization_eqs = ieqs,
        initial_conditions = Dict(Pmech0 => missing, s30 => missing, s40 => missing, s50 => missing,
            s90 => missing, fsr0 => missing))
end
