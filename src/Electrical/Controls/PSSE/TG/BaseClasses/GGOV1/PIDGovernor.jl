# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/TG/BaseClasses/GGOV1/PIDGovernor.mo (model)
# Blocks: KPGOV = Gain(Kpgov), s2 = Integrator(k = 1, InitialOutput, y_start = s20), s1 = Derivative(Kdgov, Tdgov,
# y_start = 0, InitialOutput), GovernorPID = Add3, deadZone = DeadZone(uMax = db), limiterSerror = Limiter(maxerr,
# minerr), add3_2 = Add3(k1 = -1, k3 = -1), r = Gain(R), add2 = Add, s7 = LimIntegrator(k = Kimw, outMax = 1.1*R,
# InitialOutput, y_start = s70), add3 = Add(k2 = -1), s0 = SimpleLag(1, T_pelec, y_start = s00),
# KPGOV1 = Gain(Kigov), rSELECT = R_select(Rselect). Ports as plain variables: PELEC, PMW_SET, P_REF, SPEED,
# VSTROKE, GOVOUT1 (inputs), FSRN (output).
# Six `fixed = false` parameters whose chain starts at the input PELEC: `missing` parameters with their equations in
# `initialization_eqs`, in the .mo's order (F-33), reaching `s0`, `s2` and `s7` symbolically (F-38).
# `DeadZone(uMax = db)` with the default `uMin = -uMax`, as the .mo leaves it.
# Omitted: graphical annotations.

@component function PIDGovernor(; name, Rselect = 1, R = 0.04, T_pelec = 1, maxerr = 0.05, minerr = -0.05,
        Kpgov = 10, Kigov = 2, Kdgov = 0, Tdgov = 1, Kturb = 1.5, Kimw = 0, db = 0, Wfnl = 0.2, Dm = 0)
    Rselectn = Rselect   # the Integer value: `@parameters` below rebinds `Rselect` to the symbol (F-22)
    R, T_pelec, maxerr, minerr, Kpgov, Kigov, Kdgov, Tdgov, Kturb, Kimw, db, Wfnl, Dm =
        float.((R, T_pelec, maxerr, minerr, Kpgov, Kigov, Kdgov, Tdgov, Kturb, Kimw, db, Wfnl, Dm))
    n = (; R, T_pelec, maxerr, minerr, Kpgov, Kigov, Kdgov, Tdgov, Kturb, Kimw, db, Wfnl, Dm)
    pars = @parameters begin
        Rselect = Rselect, [description = "Feedback signal for governor droop"]
        R = R, [description = "Permanent droop"]
        T_pelec = T_pelec, [description = "Electrical power transducer time constant"]
        maxerr = maxerr, [description = "Maximum value for speed error signal"]
        minerr = minerr, [description = "Minimum value for speed error signal"]
        Kpgov = Kpgov, [description = "Governor proportional gain"]
        Kigov = Kigov, [description = "Governor integral gain"]
        Kdgov = Kdgov, [description = "Governor derivative gain"]
        Tdgov = Tdgov, [description = "Governor derivative controller time constant"]
        Kturb = Kturb, [description = "Turbine gain"]
        Kimw = Kimw, [description = "Power controller (reset) gain"]
        db = db, [description = "Speed governor deadband"]
        Wfnl = Wfnl, [description = "No load fuel flow"]
        Dm = Dm, [description = "Mechanical damping coefficient"]
        Pe0, [guess = 1.0]
        Pmech0, [guess = 1.0]
        s00, [guess = 1.0]
        s20, [guess = 1.0]
        s70, [guess = 0.0]
        fsr0, [guess = 1.0]
    end
    systems = @named begin
        KPGOV = Gain(; k = n.Kpgov)
        s2 = Integrator(; k = 1, initType = :InitialOutput, y_start = s20)
        s1 = Derivative(; k = n.Kdgov, T = n.Tdgov, y_start = 0, initType = :InitialOutput)
        GovernorPID = Add3()
        deadZone = DeadZone(; uMax = n.db)
        limiterSerror = Limiter(; uMax = n.maxerr, uMin = n.minerr)
        add3_2 = Add3(; k1 = -1, k3 = -1)
        r = Gain(; k = n.R)
        add2 = Add()
        s7 = LimIntegrator(; k = n.Kimw, outMax = 1.1 * n.R, initType = :InitialOutput, y_start = s70)
        add3 = Add(; k2 = -1)
        s0 = SimpleLag(; T = n.T_pelec, y_start = s00, K = 1)
        KPGOV1 = Gain(; k = n.Kigov)
        rSELECT = R_select(; Rselect = Rselectn)
    end
    vars = @variables begin
        PELEC(t), [description = "Machine electrical power (pu)"]
        PMW_SET(t), [description = "Supervisory Load Controller Setpoint"]
        P_REF(t)
        SPEED(t), [description = "Machine speed deviation from nominal (pu)"]
        VSTROKE(t), [description = "Valve Stroke"]
        GOVOUT1(t), [description = "Governor Output before Limiter"]
        FSRN(t)
    end
    eqs = Equation[
        deadZone.y ~ limiterSerror.u,     # connect(deadZone.y, limiterSerror.u)
        add3_2.y ~ deadZone.u,            # connect(add3_2.y, deadZone.u)
        add2.y ~ add3_2.u2,               # connect(add2.y, add3_2.u2)
        KPGOV.y ~ GovernorPID.u2,         # connect(KPGOV.y, GovernorPID.u2)
        PELEC ~ s0.u,                     # connect(PELEC, s0.u)
        FSRN ~ GovernorPID.y,             # connect(FSRN, GovernorPID.y)
        KPGOV1.y ~ s2.u,                  # connect(KPGOV1.y, s2.u)
        s2.y ~ GovernorPID.u3,            # connect(s2.y, GovernorPID.u3)
        s1.y ~ GovernorPID.u1,            # connect(s1.y, GovernorPID.u1)
        P_REF ~ add2.u1,                  # connect(P_REF, add2.u1)
        r.y ~ add3_2.u3,                  # connect(r.y, add3_2.u3)
        r.u ~ rSELECT.y,                  # connect(r.u, rSELECT.y)
        add3.y ~ s7.u,                    # connect(add3.y, s7.u)
        PMW_SET ~ add3.u1,                # connect(PMW_SET, add3.u1)
        s0.y ~ add3.u2,                   # connect(s0.y, add3.u2)
        s0.y ~ rSELECT.Pelect,            # connect(s0.y, rSELECT.Pelect)
        VSTROKE ~ rSELECT.ValveStroke,    # connect(VSTROKE, rSELECT.ValveStroke)
        GOVOUT1 ~ rSELECT.GovernorOutput, # connect(GOVOUT1, rSELECT.GovernorOutput)
        limiterSerror.y ~ KPGOV1.u,       # connect(limiterSerror.y, KPGOV1.u)
        KPGOV.u ~ limiterSerror.y,        # connect(KPGOV.u, limiterSerror.y)
        s1.u ~ limiterSerror.y,           # connect(s1.u, limiterSerror.y)
        add2.u2 ~ s7.y,                   # connect(add2.u2, s7.y)
        SPEED ~ add3_2.u1,                # connect(SPEED, add3_2.u1)
    ]
    ieqs = [Pe0 ~ PELEC, Pmech0 ~ PELEC, s00 ~ Pe0, s20 ~ fsr0, s70 ~ 0, fsr0 ~ (Pmech0 + Dm) / Kturb + Wfnl]
    System(eqs, t, vars, pars; name, systems, initialization_eqs = ieqs,
        initial_conditions = Dict(Pe0 => missing, Pmech0 => missing, s00 => missing, s20 => missing,
            s70 => missing, fsr0 => missing))
end
