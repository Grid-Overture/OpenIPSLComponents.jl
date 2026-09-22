# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Branches/Generic/ULTC.mo
# Discrete tap changer (Hiskens). Blocks: Modelica.Blocks.Logical.ZeroCrossing (zeroCrossing, enable = true).
# `m` is changed only inside the `when` clauses: a discrete variable (`@discretes`, start m0). The timer x1
# (`start = 0, fixed = true`) is the state. The Booleans y2l0, y3l0 are Real 0/1 (`ifelse`). The `when zeroCrossing.y
# and pre(y2l0) ... elsewhen ... pre(y3l0)` is one continuous event on `zeroCrossing.u = y5 = x1 - Ttap` whose
# imperative affect reads y2, y3 before the event (the `pre` values) and does `reinit(x1, 0)` and the tap step, with a
# DAE re-initialization (PLAN-02, F-15); the block's own y stays 0 (ZeroCrossing.jl). The ideal-transformer
# equations are literal. Omitted: graphical annotations.

@component function ULTC(; name, m0 = 1.0375, Ttap = 20, vlow = 1.04, vhigh = 1.06, m_max = 1.1, m_min = 0.9, m_step = 0.0125)
    m0, Ttap, vlow, vhigh, m_max, m_min, m_step = float.((m0, Ttap, vlow, vhigh, m_max, m_min, m_step))
    step = m_step   # number for the affect (F-22)
    pars = @parameters begin
        m0 = m0, [description = "Initial tap ratio, from power flow"]
        Ttap = Ttap, [description = "Time delay of tap change (s)"]
        vlow = vlow, [description = "Lower voltage deadband (pu)"]
        vhigh = vhigh, [description = "Upper voltage deadband (pu)"]
        m_max = m_max, [description = "Maximum tap position"]
        m_min = m_min, [description = "Minimum tap position"]
        m_step = m_step, [description = "Step size"]
    end
    disc = @discretes begin
        m(t) = m0
    end
    systems = @named begin
        zeroCrossing = ZeroCrossing()
        p = PwPin()
        n = PwPin()
    end
    vars = @variables begin
        vk(t), [description = "Voltage at primary (pu)"]
        vm(t), [description = "Voltage at secondary (pu)"]
        anglevk(t), [description = "Angle at primary (rad)"]
        anglevm(t), [description = "Angle at secondary (rad)"]
        x1(t), [description = "Timer (s)"]
        y1(t)
        y2(t)
        y3(t)
        y4(t)
        y5(t)
        y7(t)
        y6(t)
        y2l0(t), [description = "Loop breaker for when-clauses (0/1)"]
        y3l0(t), [description = "Loop breaker for when-clauses (0/1)"]
    end
    eqs = Equation[
        n.vi ~ p.vi * m,
        n.vr ~ p.vr * m,
        p.ir + n.ir * m ~ 0,
        p.ii + n.ii * m ~ 0,
        vk ~ sqrt(p.vr^2 + p.vi^2),
        vm ~ sqrt(n.vr^2 + n.vi^2),
        anglevk ~ atan(p.vi, p.vr),   # atan2
        anglevm ~ atan(n.vi, n.vr),
        der(x1) ~ y1 * y7,
        y2 + vlow - vm ~ 0,
        y3 - vhigh + vm ~ 0,
        y6 - m + m_max - m_step / 2 ~ 0,
        y4 - m + m_min - m_step / 2 ~ 0,
        y5 - x1 + Ttap ~ 0,
        y1 ~ ifelse((y2 < 0) | (y3 < 0), 1, 0),
        y7 ~ ifelse((y6 < 0) & (vm < vlow), 1, ifelse((y4 > 0) & (vm > vhigh), 1, 0)),
        y2l0 ~ ifelse(y2 < 0, 1, 0),
        y3l0 ~ ifelse(y3 < 0, 1, 0),
        zeroCrossing.u ~ y5,
        zeroCrossing.enable ~ 1,   # zeroCrossing(enable = true)
    ]
    # when zeroCrossing.y and pre(y2l0) then reinit(x1, 0); m = pre(m) + m_step; elsewhen ... pre(y3l0) ... - m_step
    tap = SymbolicContinuousCallback([zeroCrossing.u ~ 0],
        ImperativeAffect((mv, o, ctx, integ) -> o.y2 < 0 ? (; x1 = 0.0, m = mv.m + step) :
                                                 o.y3 < 0 ? (; x1 = 0.0, m = mv.m - step) : (; x1 = mv.x1, m = mv.m);
            modified = (; x1, m), observed = (; y2, y3));
        reinitializealg = OrdinaryDiffEqCore.BrownFullBasicInit())
    System(eqs, t, vars, [pars; disc]; name, systems, continuous_events = [tap], initial_conditions = Dict(x1 => 0.0))
end
