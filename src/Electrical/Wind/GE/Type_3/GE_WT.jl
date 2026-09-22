# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Wind/GE/Type_3/GE_WT.mo (extends nothing: neither SystemBase nor pfComponent; it
# carries its own SYS_base, freq and power-flow data `_V0`, `_Ang0`, `_P0`, `_Q0`, names copied as they are)
# Blocks, with the names of the .mo: turbine_Model1 = Turbine.Turbine_Model, electrical_Control1 =
# Electrical_Control.Electrical_Control, generator1 = Generator.Generator (`GE_Generator`), const = Constant(qgen)
# (instance `const_`). Ports: the pin `pwPin1`, the input `Wind_Speed`; `P`, `Q` in SYS_base (sic, the types say
# ActivePower/ReactivePower).
# The single `initial algorithm` of the .mo computes the 25 `fixed = false` parameters (the ten `wt_x*_0`, the two
# `ex_x*_0`, the three `ge_x*_0`, `qgen`, `wndtge_*`, `cp`, `theta`, `Vw`, `genbc_k_speed`, `lambda`) with two
# iterative searches (`get_Vw`, `get_theta`: a `while` with a secant step over the polynomial `cp_init`) and hands
# them to the children as parameter defaults. It is the Julia function `ge_wt_init` below (F-34), a literal copy of
# the assignment order, the searches and their constants, the `if`s on parameters included.
# **Quirk reproduced (F-72):** with the shipped data `get_theta` never converges -- at lambda = 4.85 the polynomial
# gives cp in [0.338, 0.340] for every theta in [0, 0.471] (the GE matrix expects the pitch in degrees and receives
# radians), pwind stays above pmech, the `while` exhausts its range and `thetaOUT` is never assigned. OpenModelica
# returns the last iterate of the loop, 0.4700000000000003 (`turbine_Model1.limIntegrator1.y(0)` of the oracle),
# and so does this function: an output the loop never assigned takes the loop variable's final value (same rule for
# `get_Vw`). The Test therefore does not start at an equilibrium (the pitch integrator sits at 0.47 and runs to
# pimax); that is the .mo, and the oracle captures it.
# Dead, sic: `nmass` (always two masses), `wndtge_wn/m1/q11/q21` and `masflg` (the `masflg == 3` branch would divide
# by zero), the `import`s. `Kl` is passed to the turbine as `KI`. Omitted: graphical annotations.

@component function GE_WT(; name, _V0 = 1.03, _Ang0 = 0.00735136412, _P0 = 162000000, _Q0 = -37049223.1185345,
        GEN_base = 180000000, WT_base = 162000000, SYS_base = 100000000, freq = 60, poles = 3, Tp = 0.3,
        Kpp = 150.0, Kip = 25.0, Kpc = 3.0, Kic = 30.0, pimax = 0.47123889803, pimin = 0.0, pirat = 10.0,
        pwmax = 1.12, pwmin = 0.1, pwrat = 0.45, Kptrq = 3.0, Kitrq = 0.6, Tpc = 0.05, KQi = 0.1, KVi = 40,
        xiqmax = 0.4, xiqmin = -0.5, Kpllp = 30, Xpp = 0.8, qmax = 0.312, qmin = -0.436, nmass = 2, Hg = 0.62,
        H = 4.33, Ktg = 1.11, Dtg = 1.5, Kl = 56.6)
    _V0, _Ang0, _P0, _Q0, GEN_base, WT_base, SYS_base, freq, Tp, Kpp, Kip, Kpc, Kic, pimax, pimin, pirat =
        float.((_V0, _Ang0, _P0, _Q0, GEN_base, WT_base, SYS_base, freq, Tp, Kpp, Kip, Kpc, Kic, pimax, pimin, pirat))
    pwmax, pwmin, pwrat, Kptrq, Kitrq, Tpc, KQi, KVi, xiqmax, xiqmin, Kpllp, Xpp, qmax, qmin, Hg, H, Ktg, Dtg, Kl =
        float.((pwmax, pwmin, pwrat, Kptrq, Kitrq, Tpc, KQi, KVi, xiqmax, xiqmin, Kpllp, Xpp, qmax, qmin, Hg, H, Ktg, Dtg, Kl))
    # the protected parameters of the .mo, in its order
    Lpp = Xpp
    wbase = 2 * pi * freq / poles
    pelec = _P0 / WT_base
    pmech = pelec
    wndtge_wn = 0.0
    wndtge_m1 = 0.0
    wndtge_q11 = 0.0
    wndtge_q21 = 0.0
    masflg = 1
    ini = ge_wt_init(_V0, _Ang0, _P0, _Q0, GEN_base, Lpp, Kl, Kip, Kpc, Kitrq, Ktg, pimin, pimax, pelec, pmech,
        masflg, wndtge_wn, wndtge_m1, wndtge_q11, wndtge_q21)
    systems = @named begin
        pwPin1 = PwPin()
        turbine_Model1 = Turbine_Model(; GEN_base, Kic, Kip, Kitrq, Kpc, Kpp, Kptrq, pimax, pimin, pirat, pwmax, pwmin,
            pwrat, Tp, Tpc, wt_x0_0 = ini.wt_x0_0, wt_x1_0 = ini.wt_x1_0, wt_x2_0 = ini.wt_x2_0, wt_x3_0 = ini.wt_x3_0,
            wt_x4_0 = ini.wt_x4_0, wt_x5_0 = ini.wt_x5_0, wt_x6_0 = ini.wt_x6_0, wt_x7_0 = ini.wt_x7_0,
            wt_x8_0 = ini.wt_x8_0, wt_x9_0 = ini.wt_x9_0, WT_base, Dtg, H, Hg, KI = Kl, Ktg, wndtge_kp = ini.wndtge_kp,
            wbase, wndtge_ang0 = ini.wndtge_ang0, wndtge_spd0 = ini.wndtge_spd0)
        electrical_Control1 = Electrical_Control(; ex_x0_0 = ini.ex_x0_0, ex_x1_0 = ini.ex_x1_0, KQi, qmax, qmin, KVi,
            xiqmax, xiqmin)
        generator1 = GE_Generator(; freq, ge_x0_0 = ini.ge_x0_0, ge_x1_0 = ini.ge_x1_0, ge_x2_0 = ini.ge_x2_0, GEN_base,
            Kpllp, Lpp, SYS_base)
        const_ = OpenIPSLComponents.Constant(; k = ini.qgen)
    end
    pars = @parameters begin
        _V0 = _V0, [description = "Terminal Voltage from Power Flow (pu)"]
        _Ang0 = _Ang0, [description = "Terminal Angle from Power Flow (rad)"]
        _P0 = _P0, [description = "Active Power from Power Flow (W)"]
        _Q0 = _Q0, [description = "Reactive Power from Power Flow (var)"]
        GEN_base = GEN_base, [description = "Base Power from the Electrical Generator (VA)"]
        WT_base = WT_base, [description = "Base Power from the Turbine (VA)"]
        SYS_base = SYS_base, [description = "Base Power from the power system (VA)"]
        freq = freq, [description = "Steady state Frequency of the power system (Hz)"]
        poles = poles, [description = "Number of pole pairs"]
        Tp = Tp, [description = "Time Constant Pitch command (s)"]
        Kpp = Kpp, [description = "Pitch Control gain"]
        Kip = Kip, [description = "Gain of integrator of Pitch Control"]
        Kpc = Kpc, [description = "Pitch Compensation gain"]
        Kic = Kic, [description = "Gain of integrator of Pitch Compensation"]
        pimax = pimax, [description = "Maximum pitch angle (rad)"]
        pimin = pimin, [description = "minimum pitch angle (rad)"]
        pirat = pirat, [description = "maximum variation rate of pitch angle"]
        pwmax = pwmax, [description = "Maximal power taken from the wind (pu)"]
        pwmin = pwmin, [description = "Minimal power taken from the wind (pu)"]
        pwrat = pwrat, [description = "maximum variation rate of power taken from the wind"]
        Kptrq = Kptrq, [description = "Gain Torque Controller"]
        Kitrq = Kitrq, [description = "Gain of integrator of Torque Controller"]
        Tpc = Tpc, [description = "Time Constant Torque controller (s)"]
        KQi = KQi, [description = "Gain constant of first PI in DFIG electrical control model"]
        KVi = KVi, [description = "Gain constant of second PI in DFIG electrical control model"]
        xiqmax = xiqmax, [description = "Up saturation of second PI in DFIG electrical control model"]
        xiqmin = xiqmin, [description = "Down saturation of second PI in DFIG electrical control model"]
        Kpllp = Kpllp
        Xpp = Xpp
        qmax = qmax
        qmin = qmin
        nmass = nmass, [description = "Mono-mass or Two-mass model (dead)"]
        Hg = Hg, [description = "Inertia 2 (s)"]
        H = H, [description = "Inertia (s)"]
        Ktg = Ktg, [description = "Gain for 2 mass model"]
        Dtg = Dtg, [description = "Damping"]
        Kl = Kl
        Lpp = Lpp
        wbase = wbase
        pelec = pelec
        pmech = pmech
        wt_x0_0 = ini.wt_x0_0
        wt_x1_0 = ini.wt_x1_0
        wt_x2_0 = ini.wt_x2_0
        wt_x3_0 = ini.wt_x3_0
        wt_x4_0 = ini.wt_x4_0
        wt_x5_0 = ini.wt_x5_0
        wt_x6_0 = ini.wt_x6_0
        wt_x7_0 = ini.wt_x7_0
        wt_x8_0 = ini.wt_x8_0
        wt_x9_0 = ini.wt_x9_0
        ex_x0_0 = ini.ex_x0_0
        ex_x1_0 = ini.ex_x1_0
        ge_x0_0 = ini.ge_x0_0
        ge_x1_0 = ini.ge_x1_0
        ge_x2_0 = ini.ge_x2_0
        qgen = ini.qgen
        wndtge_ang0 = ini.wndtge_ang0
        wndtge_spd0 = ini.wndtge_spd0
        wndtge_spdwmx = ini.wndtge_spdwmx
        wndtge_spdwmn = ini.wndtge_spdwmn
        wndtge_kp = ini.wndtge_kp, [description = "Power coefficient"]
        cp = ini.cp
        theta = ini.theta
        Vw = ini.Vw
        genbc_k_speed = ini.genbc_k_speed
        wndtge_spdw1 = ini.wndtge_spdw1
        wndtge_wn = wndtge_wn
        wndtge_m1 = wndtge_m1
        wndtge_q11 = wndtge_q11
        wndtge_q21 = wndtge_q21
        lambda = ini.lambda
        masflg = masflg
    end
    vars = @variables begin
        P(t), [description = "Active Power produced in SYS_base"]
        Q(t), [description = "Reactive Power produced in SYS_base"]
        Wind_Speed(t), [description = "Wind speed input (m/s)"]
    end
    eqs = Equation[
        connect(pwPin1, generator1.p),
        generator1.Pgen ~ turbine_Model1.Pelec,               # connect(generator1.Pgen, turbine_Model1.Pelec)
        Wind_Speed ~ turbine_Model1.Wind_Speed,               # connect(Wind_Speed, turbine_Model1.Wind_Speed)
        turbine_Model1.Pord ~ electrical_Control1.Pord,       # connect(turbine_Model1.Pord, electrical_Control1.Pord)
        const_.y ~ electrical_Control1.Qord,                  # connect(const.y, electrical_Control1.Qord)
        P ~ generator1.Pgen * GEN_base / SYS_base,
        Q ~ generator1.Qgen * GEN_base / SYS_base,
        electrical_Control1.Ipcmd ~ generator1.Ipcmd,         # connect(electrical_Control1.Ipcmd, generator1.Ipcmd)
        electrical_Control1.Efd ~ generator1.Efd,             # connect(electrical_Control1.Efd, generator1.Efd)
        generator1.Qgen ~ electrical_Control1.Qgen,           # connect(generator1.Qgen, electrical_Control1.Qgen)
        generator1.Vt ~ electrical_Control1.Vterm,            # connect(generator1.Vt, electrical_Control1.Vterm)
    ]
    System(eqs, t, vars, pars; name, systems)
end

# The three protected functions of GE_WT.mo, literal.
function ge_cp_init(lambda, theta)
    lambda_vec = [1.0, lambda, lambda^2, lambda^3, lambda^4]
    theta_vec = [1.0, theta, theta^2, theta^3, theta^4]
    prod = GE_CP_COEFF * lambda_vec
    prod[1] * theta_vec[1] + prod[2] * theta_vec[2] + prod[3] * theta_vec[3] + prod[4] * theta_vec[4] + prod[5] * theta_vec[5]
end

function ge_get_Vw(pimin, wndtge_kl, wndtge_kp, genbc_k_speed, pmech)
    last_err = 99999.0
    lambda = 15 + 0.001
    stop = false
    lambdaOUT = NaN
    lambda_sav = NaN
    while lambda >= 2.001 && !stop
        lambda = lambda - 0.001
        cp = ge_cp_init(lambda, pimin)
        Vw = wndtge_kl * genbc_k_speed / lambda
        pwind = wndtge_kp * cp * Vw^3
        new_err = pwind - pmech
        if abs(new_err) <= 0.01
            lambdaOUT = lambda
            stop = true
        else
            if abs(new_err - last_err) < abs(new_err + last_err) || last_err > 90000.0
                last_err = new_err
                lambda_sav = lambda
            else
                lambdaOUT = lambda_sav - last_err * (lambda - lambda_sav) / (new_err - last_err)
                cp = ge_cp_init(lambdaOUT, 0.0)
                Vw = wndtge_kl * genbc_k_speed / lambdaOUT
                stop = true
            end
        end
    end
    isnan(lambdaOUT) ? lambda : lambdaOUT   # an output the loop never assigned: OpenModelica's value is the last iterate (F-72)
end

function ge_get_theta(lambda, Vw, wndtge_kl, wndtge_kp, genbc_k_speed, pmech, pimin, pimax)
    last_err = 99999.0
    theta = pimin - 0.005
    stop = false
    Vw1 = Vw
    thetaOUT = NaN
    theta_sav = NaN
    while theta <= pimax - 0.005 && !stop
        theta = theta + 0.005
        cp = ge_cp_init(lambda, theta)
        pwind = wndtge_kp * cp * Vw1^3
        new_err = pwind - pmech
        if abs(new_err) <= 0.01
            thetaOUT = theta
            stop = true
        else
            if abs(new_err - last_err) < abs(new_err + last_err) || last_err > 90000
                last_err = new_err
                theta_sav = theta
            else
                thetaOUT = theta_sav - last_err * (theta - theta_sav) / (new_err - last_err)
                cp = ge_cp_init(lambda, thetaOUT)
                Vw1 = wndtge_kl * genbc_k_speed / lambda
                stop = true
            end
        end
    end
    isnan(thetaOUT) ? theta : thetaOUT   # never assigned with the shipped data: the last iterate, 0.47 (F-72)
end

# The `initial algorithm` of GE_WT.mo, in its order of assignment (wndtge_kp is assigned twice: the 0.00159 only
# serves the two searches).
function ge_wt_init(_V0, _Ang0, _P0, _Q0, GEN_base, Lpp, Kl, Kip, Kpc, Kitrq, Ktg, pimin, pimax, pelec, pmech,
        masflg, wndtge_wn, wndtge_m1, wndtge_q11, wndtge_q21)
    eps = Modelica.Constants.eps
    wndtge_spdwmx = 25.0
    wndtge_spdwmn = 3.0
    wndtge_spdw1 = 14.0
    genbc_k_speed = 1.2
    wndtge_kp = 0.00159
    qgen = _Q0 / GEN_base
    ge_x0_0 = _V0 + _Q0 / GEN_base * Lpp / _V0
    ge_x1_0 = _P0 / GEN_base / _V0
    ge_x2_0 = _Ang0
    ex_x0_0 = _V0
    ex_x1_0 = ge_x0_0
    wndtge_spd0 = pmech < 0.75 ? ((-0.67 * pmech) + 1.42) * pmech + 0.51 : genbc_k_speed
    theta = pimin
    lambda = ge_get_Vw(pimin, Kl, wndtge_kp, genbc_k_speed, pmech)
    lambda = lambda + 0.01
    cp = ge_cp_init(lambda, 0.0)
    Vw = Kl * genbc_k_speed / lambda
    if wndtge_spdw1 > wndtge_spdwmx
        wndtge_spdw1 = wndtge_spdwmx
    end
    if wndtge_spdw1 < wndtge_spdwmn
        wndtge_spdw1 = wndtge_spdwmn
    end
    if pmech >= 1.0 && wndtge_spdw1 > Vw
        Vw = wndtge_spdw1
        lambda = Kl * genbc_k_speed / Vw
        theta = ge_get_theta(lambda, Vw, Kl, wndtge_kp, genbc_k_speed, pmech, pimin, pimax)
        cp = ge_cp_init(lambda, theta)
        Vw = Kl * genbc_k_speed / lambda
    end
    wndtge_kp = pmech / (cp * Vw^3)
    wt_x0_0 = theta
    wt_x1_0 = Kip <= eps ? 0.0 : theta - Kpc * (pelec - 1.0)
    wt_x4_0 = pelec
    wt_x2_0 = Kitrq <= eps ? 0.0 : wt_x4_0 / genbc_k_speed
    wt_x3_0 = 0.0
    wt_x5_0 = genbc_k_speed
    wt_x6_0 = 0.0
    wt_x7_0 = masflg == 3 ? pmech / genbc_k_speed / (wndtge_wn * wndtge_wn * wndtge_m1) * (wndtge_q11 - wndtge_q21) : 0.0
    wt_x8_0 = 0.0
    wt_x9_0 = 0.0
    wndtge_ang0 = -pmech / (Ktg * genbc_k_speed)
    (; wndtge_spdwmx, wndtge_spdwmn, wndtge_spdw1, genbc_k_speed, wndtge_kp, qgen, ge_x0_0, ge_x1_0, ge_x2_0,
        ex_x0_0, ex_x1_0, wndtge_spd0, theta, lambda, cp, Vw, wt_x0_0, wt_x1_0, wt_x2_0, wt_x3_0, wt_x4_0, wt_x5_0,
        wt_x6_0, wt_x7_0, wt_x8_0, wt_x9_0, wndtge_ang0)
end
