# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/TG/BaseClasses/GGOV1/PIDGovernorDU.mo (model)
# Twin of PIDGovernor.jl with the GGOV1DU integral path: `KPGOV1 = Gain(Kigov/Kpgov)` fed by the extra
# `LoadlimiterPI2 = Add(k1 = -1)` on (s2.y, GOVOUT1) instead of by `limiterSerror.y`, i.e. the integrator is reset by
# the difference between its own output and the limited governor output. Same parameters (`Kimw` and `db` are
# declared in the other order in the .mo, which changes nothing) and the same six `fixed = false` chain.
# Omitted: graphical annotations.

@component function PIDGovernorDU(; name, Rselect = 1, R = 0.04, T_pelec = 1, maxerr = 0.05, minerr = -0.05,
        Kpgov = 10, Kigov = 2, Kdgov = 0, Tdgov = 1, Kturb = 1.5, Wfnl = 0.2, Kimw = 0, db = 0, Dm = 0)
    Rselectn = Rselect   # the Integer value: `@parameters` below rebinds `Rselect` to the symbol (F-22)
    R, T_pelec, maxerr, minerr, Kpgov, Kigov, Kdgov, Tdgov, Kturb, Wfnl, Kimw, db, Dm =
        float.((R, T_pelec, maxerr, minerr, Kpgov, Kigov, Kdgov, Tdgov, Kturb, Wfnl, Kimw, db, Dm))
    n = (; R, T_pelec, maxerr, minerr, Kpgov, Kigov, Kdgov, Tdgov, Kturb, Wfnl, Kimw, db, Dm)
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
        Wfnl = Wfnl, [description = "No load fuel flow"]
        Kimw = Kimw, [description = "Power controller (reset) gain"]
        db = db, [description = "Speed governor deadband"]
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
        KPGOV1 = Gain(; k = n.Kigov / n.Kpgov)
        LoadlimiterPI2 = Add(; k1 = -1)
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
        add3.y ~ s7.u,                    # connect(add3.y, s7.u)
        s2.u ~ KPGOV1.y,                  # connect(s2.u, KPGOV1.y)
        KPGOV1.u ~ LoadlimiterPI2.y,      # connect(KPGOV1.u, LoadlimiterPI2.y)
        PELEC ~ s0.u,                     # connect(PELEC, s0.u)
        FSRN ~ GovernorPID.y,             # connect(FSRN, GovernorPID.y)
        add3_2.u3 ~ r.y,                  # connect(add3_2.u3, r.y)
        add2.u2 ~ s7.y,                   # connect(add2.u2, s7.y)
        P_REF ~ add2.u1,                  # connect(P_REF, add2.u1)
        SPEED ~ add3_2.u1,                # connect(SPEED, add3_2.u1)
        rSELECT.y ~ r.u,                  # connect(rSELECT.y, r.u)
        PMW_SET ~ add3.u1,                # connect(PMW_SET, add3.u1)
        s0.y ~ add3.u2,                   # connect(s0.y, add3.u2)
        s0.y ~ rSELECT.Pelect,            # connect(s0.y, rSELECT.Pelect)
        VSTROKE ~ rSELECT.ValveStroke,    # connect(VSTROKE, rSELECT.ValveStroke)
        GOVOUT1 ~ rSELECT.GovernorOutput, # connect(GOVOUT1, rSELECT.GovernorOutput)
        KPGOV.y ~ GovernorPID.u2,         # connect(KPGOV.y, GovernorPID.u2)
        s1.y ~ GovernorPID.u1,            # connect(s1.y, GovernorPID.u1)
        s2.y ~ GovernorPID.u3,            # connect(s2.y, GovernorPID.u3)
        LoadlimiterPI2.u1 ~ s2.y,         # connect(LoadlimiterPI2.u1, s2.y)
        GOVOUT1 ~ LoadlimiterPI2.u2,      # connect(GOVOUT1, LoadlimiterPI2.u2)
        limiterSerror.y ~ KPGOV.u,        # connect(limiterSerror.y, KPGOV.u)
        s1.u ~ limiterSerror.y,           # connect(s1.u, limiterSerror.y)
    ]
    ieqs = [Pe0 ~ PELEC, Pmech0 ~ PELEC, s00 ~ Pe0, s20 ~ fsr0, s70 ~ 0, fsr0 ~ (Pmech0 + Dm) / Kturb + Wfnl]
    System(eqs, t, vars, pars; name, systems, initialization_eqs = ieqs,
        initial_conditions = Dict(Pe0 => missing, Pmech0 => missing, s00 => missing, s20 => missing,
            s70 => missing, fsr0 => missing))
end
