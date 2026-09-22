# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Renewables/PSSE/PlantController/REPCA1.mo (extends BaseClasses/BaseREPC.mo)
# The WECC plant controller: a reactive channel (line-drop compensation or reactive droop -> filter -> Q or V
# reference -> dead zone -> limiter -> PI with anti-windup -> lead-lag -> Qext) and an active channel (frequency
# error -> dead zone -> the two droop gains with their one-sided limiters -> power error -> PI -> limiter ->
# lag -> Pref). Blocks with the .mo's own names.
# `V0`, `p00` and `q00` are `parameter (fixed = false)` whose `initial equation` reads an **input** (`p00 = p0`,
# `q00 = q0`, `v0 = V0` -- sic, that last one is written with the input on the left): F-33, i.e. a `guess`, a
# `missing` entry in `initial_conditions` and the equation in `initialization_eqs`. Everything derived from them is
# a chain of `missing` (F-38): the `y_start` of `simpleLag`, `simpleLag1`, `KIG` (p00), `simpleLag2`, `leadLag` and
# `pI_No_Windup_notVariable` (q00).
# `Vref0 = if (Vref > 0 or Vref < 0) then Vref else V0` is decided in Julia (`Vref` is a numeric keyword argument,
# F-50); when it selects `V0` it passes the `missing` symbol. `Vref` itself is a parameter whose default is another
# parameter (`Vref = v_0`), written as the keyword-argument default.
# `Voltage_dip = if vreg < Vfrz then true else false` is an algebraic 0/1 variable with an `ifelse`, no event
# (precedent `TGTypeI`; with `Vfrz = 0` it never fires).
# The three flag switches (`VCFLAG`, `REFFLAG`, `FREQ_FLAG`) are instantiated literally with their
# `BooleanConstant`, as `REGCA1`'s `switch1` is, so the OpenModelica columns compare.
# Quirk that is replicated: `Freq` and `Freq_ref` arrive in Hz (the plant feeds them `Constant(k = fn)`) while the
# bands `fdbd1/2`, `Ddn`, `Dup` are meant in pu; in the three Tests and in every case both inputs are `fn` and the
# whole active-droop branch is identically zero.
# `LeadLag` with `T1 = Tft = 0` and `T2 = Tfv` is an ordinary first-order lag (the block handles it).
# Omitted: Icons.VerifiedModel, graphical annotations.

@component function REPCA1(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        M_b = nothing, vcflag = true, refflag = true, fflag = true,
        Tfltr = 0.02, Kp = 18, Ki = 5, Tft = 0, Tfv = 0.075, Vfrz = 0, Rc = 0.0025, Xc = 0.0025, Kc = 0.02,
        emax = 0.1, emin = -0.1, dbd1 = 0, dbd2 = 0, Qmax = 0.4360, Qmin = -0.4360, Kpg = 0.1, Kig = 0.05,
        Tp = 0.25, fdbd1 = 0, fdbd2 = 0, femax = 999, femin = -999, Pmax = 999, Pmin = -999, Tg = 0.1,
        Ddn = 20, Dup = 0, Vref = v_0)
    S_b, V_b, fn, P_0, Q_0, v_0, angle_0 = float.((S_b, V_b, fn, P_0, Q_0, v_0, angle_0))
    Tfltr, Kp, Ki, Tft, Tfv, Vfrz, Rc, Xc, Kc = float.((Tfltr, Kp, Ki, Tft, Tfv, Vfrz, Rc, Xc, Kc))
    emax, emin, dbd1, dbd2, Qmax, Qmin, Kpg, Kig, Tp = float.((emax, emin, dbd1, dbd2, Qmax, Qmin, Kpg, Kig, Tp))
    fdbd1, fdbd2, femax, femin, Pmax, Pmin, Tg, Ddn, Dup, Vref =
        float.((fdbd1, fdbd2, femax, femin, Pmax, Pmin, Tg, Ddn, Dup, Vref))
    n = (; Tfltr, Kp, Ki, Tft, Tfv, Kc, emax, emin, dbd1, dbd2, Qmax, Qmin, Kpg, Kig, Tp,
        fdbd1, fdbd2, femax, femin, Pmax, Pmin, Tg, Ddn, Dup, Vref)   # numeric copies for the blocks (F-22)
    inf = Modelica.Constants.inf
    base = BaseREPC(; name, S_b, V_b, fn, P_0, Q_0, v_0, angle_0, M_b)
    @unpack CoB, Qref, Plant_pref, Freq, Freq_ref, Qext, Pref, p0, q0, v0,
        branch_ir, branch_ii, regulate_vr, regulate_vi = base
    pars = @parameters begin
        Vfrz = Vfrz, [description = "Voltage below which State s2 is frozen"]
        Rc = Rc, [description = "Line drop compensation resistance (pu)"]
        Xc = Xc, [description = "Line drop compensation reactance (pu)"]
        V0, [guess = v_0]
        p00, [guess = P_0 / (M_b === nothing ? S_b : float(M_b))]
        q00, [guess = Q_0 / (M_b === nothing ? S_b : float(M_b))]
    end
    # Vref0 = if (Vref > 0 or Vref < 0) then Vref else V0 -- a decision on a numeric keyword argument (F-50);
    # choosing V0 passes the `missing` symbol down the chain (F-38)
    Vref0 = (Vref > 0 || Vref < 0) ? Vref : V0
    systems = @named begin
        add = Add(; k1 = -1)
        DDN = Gain(; k = n.Ddn)
        DUP = Gain(; k = n.Dup)
        limiter = Limiter(; uMax = 0.0, uMin = -inf)
        limiter1 = Limiter(; uMax = inf, uMin = 0.0)
        add1 = Add(; k1 = 1)
        add3_1 = Add3(; k2 = -1)
        simpleLag = SimpleLag(; K = 1, T = n.Tp, y_start = p00)
        limiter2 = Limiter(; uMax = n.femax, uMin = n.femin)
        KPG = Gain(; k = n.Kpg)
        KIG = Integrator(; k = n.Kig, initType = :InitialState, y_start = p00)
        add2 = Add(; k1 = 1)
        limiter3 = Limiter(; uMax = n.Pmax, uMin = n.Pmin)
        simpleLag1 = SimpleLag(; K = 1, T = n.Tg, y_start = p00)
        FREQ_FLAG = Switch()
        FREQ_FLAG_logic = BooleanConstant(; k = fflag)
        Vreg = RealExpression(; expr = nothing)          # y = vreg, a variable of this model (F-22)
        Qbranch = RealExpression(; expr = nothing)       # y = qbranch
        Pbranch = RealExpression(; expr = nothing)       # y = pbranch
        Voltage_diff = RealExpression(; expr = nothing)  # y = voltage_diff
        VCFLAG = Switch()
        add3 = Add(; k1 = 1)
        KC = Gain(; k = n.Kc)
        VCFLAG_logic = BooleanConstant(; k = vcflag)
        simpleLag2 = SimpleLag(; K = 1, T = n.Tfltr, y_start = q00)
        add4 = Add(; k1 = -1)
        REFFLAG = Switch()
        REFFLAG_logic = BooleanConstant(; k = refflag)
        simpleLag3 = SimpleLag(; K = 1, T = n.Tfltr, y_start = Vref0)
        add5 = Add(; k1 = 1, k2 = -1)
        limiter4 = Limiter(; uMax = n.emax, uMin = n.emin)
        VREF = OpenIPSLComponents.Constant(; k = n.Vref)
        leadLag = LeadLag(; K = 1, T1 = n.Tft, T2 = n.Tfv, y_start = q00, x_start = 0)
        deadZone = DeadZone(; uMax = n.dbd2, uMin = n.dbd1)
        deadZone1 = DeadZone(; uMax = n.fdbd2, uMin = n.fdbd1)
        pI_No_Windup_notVariable = PIwithNoVariableLimiter(; K_P = n.Kp, K_I = n.Ki, V_RMAX = n.Qmax,
            V_RMIN = n.Qmin, y_start = q00)
        VLogic = BooleanExpression(; expr = nothing)     # y = Voltage_dip
    end
    vars = @variables begin
        voltage_diff(t)
        vreg(t)
        qbranch(t)
        pbranch(t)
        Voltage_dip(t), [description = "Voltage dip flag (0/1)"]
    end
    eqs = Equation[
        Voltage_dip ~ ifelse(vreg < Vfrz, 1.0, 0.0),
        voltage_diff ~ sqrt((regulate_vr - Rc * branch_ir / CoB + Xc * branch_ii / CoB)^2 +
                            (regulate_vi - Xc * branch_ir / CoB - Rc * branch_ii / CoB)^2),
        vreg ~ sqrt(regulate_vr^2 + regulate_vi^2),
        qbranch ~ (1 / CoB) * (regulate_vi * branch_ir - regulate_vr * branch_ii),
        pbranch ~ (1 / CoB) * (regulate_vr * branch_ir + regulate_vi * branch_ii),
        # the four RealExpression blocks and the BooleanExpression, whose `y` reads a variable of this model
        Vreg.y ~ vreg,
        Qbranch.y ~ qbranch,
        Pbranch.y ~ pbranch,
        Voltage_diff.y ~ voltage_diff,
        VLogic.y ~ Voltage_dip,
        DDN.y ~ limiter.u,                   # connect(DDN.y, limiter.u)
        DUP.y ~ limiter1.u,                  # connect(DUP.y, limiter1.u)
        limiter.y ~ add1.u1,                 # connect(limiter.y, add1.u1)
        limiter1.y ~ add1.u2,                # connect(limiter1.y, add1.u2)
        add1.y ~ add3_1.u3,                  # connect(add1.y, add3_1.u3)
        simpleLag.y ~ add3_1.u2,             # connect(simpleLag.y, add3_1.u2)
        Plant_pref ~ add3_1.u1,              # connect(Plant_pref, add3_1.u1)
        add3_1.y ~ limiter2.u,               # connect(add3_1.y, limiter2.u)
        limiter2.y ~ KIG.u,                  # connect(limiter2.y, KIG.u)
        KPG.u ~ limiter2.y,                  # connect(KPG.u, limiter2.y)
        KIG.y ~ add2.u2,                     # connect(KIG.y, add2.u2)
        KPG.y ~ add2.u1,                     # connect(KPG.y, add2.u1)
        add2.y ~ limiter3.u,                 # connect(add2.y, limiter3.u)
        limiter3.y ~ simpleLag1.u,           # connect(limiter3.y, simpleLag1.u)
        simpleLag1.y ~ FREQ_FLAG.u1,         # connect(simpleLag1.y, FREQ_FLAG.u1)
        FREQ_FLAG_logic.y ~ FREQ_FLAG.u2,    # connect(FREQ_FLAG_logic.y, FREQ_FLAG.u2)
        FREQ_FLAG.y ~ Pref,                  # connect(FREQ_FLAG.y, Pref)
        Pbranch.y ~ simpleLag.u,             # connect(Pbranch.y, simpleLag.u)
        Vreg.y ~ add3.u1,                    # connect(Vreg.y, add3.u1)
        Qbranch.y ~ KC.u,                    # connect(Qbranch.y, KC.u)
        KC.y ~ add3.u2,                      # connect(KC.y, add3.u2)
        simpleLag2.u ~ KC.u,                 # connect(simpleLag2.u, KC.u)
        simpleLag2.y ~ add4.u1,              # connect(simpleLag2.y, add4.u1)
        add4.y ~ REFFLAG.u3,                 # connect(add4.y, REFFLAG.u3)
        REFFLAG_logic.y ~ REFFLAG.u2,        # connect(REFFLAG_logic.y, REFFLAG.u2)
        VCFLAG.y ~ simpleLag3.u,             # connect(VCFLAG.y, simpleLag3.u)
        simpleLag3.y ~ add5.u2,              # connect(simpleLag3.y, add5.u2)
        VREF.y ~ add5.u1,                    # connect(VREF.y, add5.u1)
        add4.u2 ~ Qref,                      # connect(add4.u2, Qref)
        REFFLAG.y ~ deadZone.u,              # connect(REFFLAG.y, deadZone.u)
        add.y ~ deadZone1.u,                 # connect(add.y, deadZone1.u)
        deadZone1.y ~ DDN.u,                 # connect(deadZone1.y, DDN.u)
        DUP.u ~ DDN.u,                       # connect(DUP.u, DDN.u)
        Freq_ref ~ add.u2,                   # connect(Freq_ref, add.u2)
        Freq ~ add.u1,                       # connect(Freq, add.u1)
        leadLag.y ~ Qext,                    # connect(leadLag.y, Qext)
        Voltage_diff.y ~ VCFLAG.u1,          # connect(Voltage_diff.y, VCFLAG.u1)
        VCFLAG_logic.y ~ VCFLAG.u2,          # connect(VCFLAG_logic.y, VCFLAG.u2)
        add3.y ~ VCFLAG.u3,                  # connect(add3.y, VCFLAG.u3)
        add5.y ~ REFFLAG.u1,                 # connect(add5.y, REFFLAG.u1)
        p0 ~ FREQ_FLAG.u3,                   # connect(p0, FREQ_FLAG.u3)
        deadZone.y ~ limiter4.u,             # connect(deadZone.y, limiter4.u)
        limiter4.y ~ pI_No_Windup_notVariable.u,   # connect(limiter4.y, pI_No_Windup_notVariable.u)
        pI_No_Windup_notVariable.y ~ leadLag.u,    # connect(pI_No_Windup_notVariable.y, leadLag.u)
        VLogic.y ~ pI_No_Windup_notVariable.voltage_dip,   # connect(VLogic.y, ...voltage_dip)
    ]
    extend(System(eqs, t, vars, pars; name, systems,
            initial_conditions = Dict(V0 => missing, p00 => missing, q00 => missing),
            initialization_eqs = [p00 ~ p0, q00 ~ q0, V0 ~ v0]), base)
end
