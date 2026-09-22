# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/TG/GGOV1.mo (extends nothing: its ports are its own)
# Ports as plain variables: SPEED and PELEC (inputs), PMECH (output).
# Blocks: AccelerationSet = Constant(Aset), P_ref = Constant(Pref), Pmw_set = Constant(Pmwset),
# set = Constant(Ldref), min_select = Min_select(frs0 = fsr0, nu = 3), gGOV1_Temp = LoadLimiter,
# V = Limiter(Vmax, Vmin), gGOV1_Turb = GGOV1_Turbine, gGOV1_Accel = AccelerationLimiter,
# gGOV1_Power = PIDGovernor.
# The causal connects are equalities; `min_select.u[1..3]` take FSRN, FSRT and FSRA.
# Five `fixed = false` parameters from the input PELEC (`Pe0`, `Pmech0`, `Pref`, `Pmwset`, `fsr0`), plus the ones
# each base declares for itself: MTK solves them all in one initialization system (F-33, F-38).
# `Trate` ("turbine rating") is declared by the .mo and used nowhere: a dead parameter, kept.
# `delay` is the `.mo`'s `Types.DelayType` as a Symbol and only `:FixedDelay` is accepted (see Turbine.jl); `pade`
# is the Julia-only fallback of `FixedDelay` for a network that also has events (F-51).
# Omitted: Icons.VerifiedModel, graphical annotations.

@component function GGOV1(; name, Rselect = 1, Flag = 1, delay = :FixedDelay, R = 0.04, T_pelec = 1, maxerr = 0.05,
        minerr = -0.05, Kpgov = 10, Kigov = 2, Kdgov = 0, Tdgov = 1, Vmax = 1, Vmin = 0.15, Tact = 0.5, Kturb = 1.5,
        Wfnl = 0.2, Tb = 0.1, Tc = 0, Teng = Modelica.Constants.eps, Tfload = 3, Kpload = 2, Kiload = 0.67,
        Ldref = 1, Dm = 0, Ropen = 0.1, Rclose = -0.1, Kimw = 0, Aset = 0.1, Ka = 10, Ta = 0.1, Trate = 0, db = 0,
        Tsa = 4, Tsb = 5, Rup = 99, Rdown = -99, DELT = 0.005, pade = 0)
    Rselectn, Flagn = Rselect, Flag   # the Integer values: `@parameters` rebinds both names (F-22)
    R, T_pelec, maxerr, minerr, Kpgov, Kigov, Kdgov, Tdgov, Vmax, Vmin, Tact, Kturb, Wfnl, Tb, Tc, Teng, Tfload,
    Kpload, Kiload, Ldref, Dm, Ropen, Rclose, Kimw, Aset, Ka, Ta, Trate, db, Tsa, Tsb, Rup, Rdown, DELT =
        float.((R, T_pelec, maxerr, minerr, Kpgov, Kigov, Kdgov, Tdgov, Vmax, Vmin, Tact, Kturb, Wfnl, Tb, Tc, Teng,
            Tfload, Kpload, Kiload, Ldref, Dm, Ropen, Rclose, Kimw, Aset, Ka, Ta, Trate, db, Tsa, Tsb, Rup, Rdown,
            DELT))
    n = (; R, T_pelec, maxerr, minerr, Kpgov, Kigov, Kdgov, Tdgov, Vmax, Vmin, Tact, Kturb, Wfnl, Tb, Tc, Teng,
        Tfload, Kpload, Kiload, Ldref, Dm, Ropen, Rclose, Kimw, Aset, Ka, Ta, db, Tsa, Tsb, DELT)
    pars = @parameters begin
        Rselect = Rselect, [description = "Feedback signal for governor droop"]
        Flag = Flag, [description = "Switch for fuel source characteristic"]
        R = R, [description = "Permanent droop"]
        T_pelec = T_pelec, [description = "Electrical power transducer time constant"]
        maxerr = maxerr, [description = "Maximum value for speed error signal"]
        minerr = minerr, [description = "Minimum value for speed error signal"]
        Kpgov = Kpgov, [description = "Governor proportional gain"]
        Kigov = Kigov, [description = "Governor integral gain"]
        Kdgov = Kdgov, [description = "Governor derivative gain"]
        Tdgov = Tdgov, [description = "Governor derivative controller time constant"]
        Vmax = Vmax, [description = "Maximum valve position limit"]
        Vmin = Vmin, [description = "Minimum valve position limit"]
        Tact = Tact, [description = "Actuator time constant"]
        Kturb = Kturb, [description = "Turbine gain"]
        Wfnl = Wfnl, [description = "No load fuel flow"]
        Tb = Tb, [description = "Turbine lag time constant"]
        Tc = Tc, [description = "Turbine lead time constant"]
        Teng = Teng, [description = "Transport lag time constant for diesel engine"]
        Tfload = Tfload, [description = "Load Limiter time constant"]
        Kpload = Kpload, [description = "Load limiter proportional gain for PI controller"]
        Kiload = Kiload, [description = "Load limiter integral gain for PI controller"]
        Ldref = Ldref, [description = "Load limiter reference value"]
        Dm = Dm, [description = "Mechanical damping coefficient"]
        Ropen = Ropen, [description = "Maximum valve opening rate"]
        Rclose = Rclose, [description = "Maximum valve closing rate"]
        Kimw = Kimw, [description = "Power controller (reset) gain"]
        Aset = Aset, [description = "Acceleration limiter setpoint"]
        Ka = Ka, [description = "Acceleration limiter gain"]
        Ta = Ta, [description = "Acceleration limiter time constant"]
        Trate = Trate, [description = "Turbine rating"]
        db = db, [description = "Speed governor deadband"]
        Tsa = Tsa, [description = "Temperature detection lead time constant"]
        Tsb = Tsb, [description = "Temperature detection lag time constant"]
        Rup = Rup, [description = "Maximum rate of load limit increase"]
        Rdown = Rdown, [description = "Maximum rate of load limit decrease"]
        DELT = DELT, [description = "Time step used in simulation"]
        Pe0, [guess = 1.0]
        Pmech0, [guess = 1.0]
        Pref, [guess = 0.04]
        Pmwset, [guess = 1.0]
        fsr0, [guess = 1.0]
    end
    systems = @named begin
        AccelerationSet = Constant(; k = n.Aset)
        P_ref = Constant(; k = Pref)
        Pmw_set = Constant(; k = Pmwset)
        set = Constant(; k = n.Ldref)
        min_select = Min_select(; frs0 = fsr0, nu = 3)
        gGOV1_Temp = LoadLimiter(; Kturb = n.Kturb, Kpload = n.Kpload, Kiload = n.Kiload, Dm = n.Dm, Wfnl = n.Wfnl)
        V = Limiter(; uMax = n.Vmax, uMin = n.Vmin)
        gGOV1_Turb = GGOV1_Turbine(; delay, Tact = n.Tact, Kturb = n.Kturb, Tb = n.Tb, Tc = n.Tc, Teng = n.Teng,
            Tfload = n.Tfload, Dm = n.Dm, Ropen = n.Ropen, Rclose = n.Rclose, Vmax = n.Vmax, Vmin = n.Vmin,
            Tsa = n.Tsa, Tsb = n.Tsb, DELT = n.DELT, Flag = Flagn, Wfnl = n.Wfnl, pade)
        gGOV1_Accel = AccelerationLimiter(; Ka = n.Ka, Ta = n.Ta, DELT = n.DELT)
        gGOV1_Power = PIDGovernor(; Rselect = Rselectn, R = n.R, T_pelec = n.T_pelec, maxerr = n.maxerr, minerr = n.minerr,
            Kpgov = n.Kpgov, Kigov = n.Kigov, Kdgov = n.Kdgov, Tdgov = n.Tdgov, Dm = n.Dm, Kimw = n.Kimw,
            db = n.db, Kturb = n.Kturb, Wfnl = n.Wfnl)
    end
    vars = @variables begin
        SPEED(t), [description = "Machine speed deviation from nominal (pu)"]
        PELEC(t), [description = "Machine electrical power (pu)"]
        PMECH(t), [description = "Turbine mechanical power (pu)"]
    end
    eqs = Equation[
        gGOV1_Turb.PMECH ~ PMECH,                  # connect(gGOV1_Turb.PMECH, PMECH)
        set.y ~ gGOV1_Temp.LDREF,                  # connect(set.y, gGOV1_Temp.LDREF)
        min_select.yMin ~ V.u,                     # connect(min_select.yMin, V.u)
        V.y ~ gGOV1_Turb.FSR,                      # connect(V.y, gGOV1_Turb.FSR)
        AccelerationSet.y ~ gGOV1_Accel.ASET,      # connect(AccelerationSet.y, gGOV1_Accel.ASET)
        gGOV1_Temp.TEXM ~ gGOV1_Turb.TEXM,         # connect(gGOV1_Temp.TEXM, gGOV1_Turb.TEXM)
        SPEED ~ gGOV1_Turb.SPEED,                  # connect(SPEED, gGOV1_Turb.SPEED)
        SPEED ~ gGOV1_Accel.SPEED,                 # connect(SPEED, gGOV1_Accel.SPEED)
        PELEC ~ gGOV1_Power.PELEC,                 # connect(PELEC, gGOV1_Power.PELEC)
        Pmw_set.y ~ gGOV1_Power.PMW_SET,           # connect(Pmw_set.y, gGOV1_Power.PMW_SET)
        P_ref.y ~ gGOV1_Power.P_REF,               # connect(P_ref.y, gGOV1_Power.P_REF)
        gGOV1_Power.SPEED ~ SPEED,                 # connect(gGOV1_Power.SPEED, SPEED)
        PELEC ~ gGOV1_Turb.PELEC,                  # connect(PELEC, gGOV1_Turb.PELEC)
        gGOV1_Turb.VSTROKE ~ gGOV1_Power.VSTROKE,  # connect(gGOV1_Turb.VSTROKE, gGOV1_Power.VSTROKE)
        PELEC ~ gGOV1_Temp.PELEC,                  # connect(PELEC, gGOV1_Temp.PELEC)
        V.y ~ gGOV1_Power.GOVOUT1,                 # connect(V.y, gGOV1_Power.GOVOUT1)
        V.y ~ gGOV1_Accel.FSR,                     # connect(V.y, gGOV1_Accel.FSR)
        gGOV1_Power.FSRN ~ min_select.u[1],        # connect(gGOV1_Power.FSRN, min_select.u[1])
        gGOV1_Temp.FSRT ~ min_select.u[2],         # connect(gGOV1_Temp.FSRT, min_select.u[2])
        gGOV1_Accel.FSRA ~ min_select.u[3],        # connect(gGOV1_Accel.FSRA, min_select.u[3])
    ]
    ieqs = [Pe0 ~ PELEC, Pmech0 ~ PELEC, Pref ~ R * Pe0, Pmwset ~ Pe0, fsr0 ~ (Pmech0 + Dm) / Kturb + Wfnl]
    System(eqs, t, vars, pars; name, systems, initialization_eqs = ieqs,
        initial_conditions = Dict(Pe0 => missing, Pmech0 => missing, Pref => missing, Pmwset => missing,
            fsr0 => missing))
end
