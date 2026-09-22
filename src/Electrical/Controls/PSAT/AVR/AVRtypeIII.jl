# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSAT/AVR/AVRtypeIII.mo
# PSAT AVR type 3, a flat model: three states (vm, vr, vf1) and one block, `limiter1`
# (Modelica.Blocks.Nonlinear.Limiter with uMax = vfmax, uMin = vfmin), instantiated as a subsystem.
# The RealInput/RealOutput ports v, vs, vf0, vf are plain variables.
# `vref` and `s0` are `parameter (fixed = false)` resolved by the .mo's `initial equation` from the *inputs* v and vs,
# so they are declared with a guess, listed as `missing` in initial_conditions and given their equations in
# initialization_eqs (F-33); the remaining three initial equations (vf1 = vf0, vm = v, vr = ...) go there too.
# Quirks replicated: `(1 + s0*(v/vm - 1))` with s0 = vs = 0 in every user of 3.1.0 (inert), and T1 = T2 in
# Example_1/Example_2/KundurSMIB, which cancels the `1 - T1/T2` term and leaves vr as a decay from 0.
# Omitted: graphical annotations.

@component function AVRtypeIII(; name, vfmax = 5, vfmin = -5, K0 = 20, T2 = 0.1, T1 = 0.45, Te = 0.1, Tr = 0.0015)
    vfmax, vfmin, K0, T2, T1, Te, Tr = float.((vfmax, vfmin, K0, T2, T1, Te, Tr))   # F-21
    pars = @parameters begin
        vfmax = vfmax, [description = "Maximum field voltage (pu)"]
        vfmin = vfmin, [description = "Minimum field voltage (pu)"]
        K0 = K0, [description = "regulator gain (pu/pu)"]
        T2 = T2, [description = "regulator pole (s)"]
        T1 = T1, [description = "Regulator zero (s)"]
        Te = Te, [description = "Field circuit time constant (s)"]
        Tr = Tr, [description = "Measurement time constant (s)"]
        vref, [guess = 1.0]   # fixed = false: resolved from the input v by the initial equation below
        s0, [guess = 0.0]     # fixed = false: resolved from the input vs by the initial equation below
    end
    systems = @named begin
        limiter1 = Limiter(; uMax = vfmax, uMin = vfmin)
    end
    vars = @variables begin
        vm(t), [description = "Measured voltage (pu)"]
        vr(t), [description = "Regulator state (pu)"]
        vf1(t), [description = "Unlimited field voltage (pu)"]
        v(t), [description = "Generator terminal voltage (pu)"]
        vf(t), [description = "Field voltage (pu)"]
        vs(t), [description = "Stabilizer signal (pu)"]
        vf0(t), [description = "Initial field voltage (pu)"]
    end
    eqs = Equation[
        der(vm) ~ (v - vm) / Tr,
        der(vr) ~ (K0 * (1 - T1 / T2) * (vref + vs - vm) - vr) / T2,
        der(vf1) ~ ((vr + K0 * (T1 / T2) * (vref + vs - vm) + vf0) * (1 + s0 * (v / vm - 1)) - vf1) / Te,
        limiter1.u ~ vf1,
        limiter1.y ~ vf,
    ]
    System(eqs, t, vars, pars; name, systems,
        initial_conditions = Dict(vref => missing, s0 => missing),
        guesses = Dict(v => 1.0, vf0 => 1.0, vm => 1.0, vf1 => 1.0, vr => 0.0),
        initialization_eqs = [
            vref ~ v,
            s0 ~ vs,
            vf1 ~ vf0,
            vm ~ v,
            vr ~ K0 * (1 - T1 / T2) * (vref + vs - vm),
        ])
end
