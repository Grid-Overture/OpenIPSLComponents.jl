# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/TG/WPIDHY.mo (extends nothing: its ports are its own)
# Ports as plain variables: SPEED and PELEC (inputs), PMECH (output). There is no PMECH0 port: the initial power is
# `PELEC` at t = 0.
# Blocks: add1 = Add(k1 = -1), const = Constant(PREF) (instance `const_`), simpleLag = SimpleLag(REG, T_REG,
# y_start = s01), add3_1 = Add3, gain = Gain(K_P), integrator = Integrator(K_I, InitialOutput, y_start = 0),
# derivative = Derivative(K_D, InitialOutput, x_start = s01), add3 = Add(k1 = -1), simpleLag1/simpleLag2 =
# SimpleLag(1, T_A, y_start = s02), derivativeLag = DerivativeLag(1, T_B, y_start = 0, x_start = s02),
# limiter = Limiter(VELMX, VELMN), integrator1 = Integrator(InitialOutput, y_start = sG), limiter1 = Limiter(GATMX,
# GATMN), combiTable1Ds = CombiTable1Ds([G0 0; G1 P1; G2 P2; 1 P3], LinearSegments), leadLag1 = LeadLag(1, -T_W,
# T_W/2, y_start = p0, x_start = 0), add2 = Add(k1 = -1), gain1 = Gain(D), limiter2 = Limiter(PMAX, PMIN).
# The causal connects are equalities.
# Seven `parameter (fixed = false)` in the `.mo`'s own order: `PREF = PELEC`, `PMECH0 = PELEC`, `p0 = PMECH0`,
# `s00 = PELEC - PREF`, `s01 = s00*REG`, `s02 = s01*K_P` and `sG`, the *inverse* of the lookup table at `p0`
# (an `if` chain over an initialization unknown, so it stays an `ifelse`). The chain starts from an input, so all
# seven are `missing` parameters with their equations in `initialization_eqs` (F-33) and they reach the blocks
# symbolically (F-38). Omitted: Icons.VerifiedModel, graphical annotations.

@component function WPIDHY(; name, T_REG = 1, REG = -0.05, K_P = 2, K_I = 0.5, K_D = 0, T_A = 0.025, T_W = 2.3,
        T_B = 0.1, VELMX = 0.1, VELMN = -0.132, GATMX = 1, GATMN = 0, PMAX = 1, PMIN = 0, D = 2, G0 = 0.08, G1 = 0.3,
        G2 = 0.75, P1 = 0.25, P2 = 0.75, P3 = 1)
    T_REG, REG, K_P, K_I, K_D, T_A, T_W, T_B, VELMX, VELMN, GATMX, GATMN, PMAX, PMIN, D, G0, G1, G2, P1, P2, P3 =
        float.((T_REG, REG, K_P, K_I, K_D, T_A, T_W, T_B, VELMX, VELMN, GATMX, GATMN, PMAX, PMIN, D, G0, G1, G2, P1,
            P2, P3))
    n = (; T_REG, REG, K_P, K_I, K_D, T_A, T_W, T_B, VELMX, VELMN, GATMX, GATMN, PMAX, PMIN, D)
    tbl = [G0 0.0; G1 P1; G2 P2; 1.0 P3]
    pars = @parameters begin
        T_REG = T_REG, [description = "Input time constant of governor, sec"]
        REG = REG, [description = "Reg Gain"]
        K_P = K_P, [description = "Proportional gain, pu"]
        K_I = K_I, [description = "Integral gain, pu"]
        K_D = K_D, [description = "Derivative gain, pu"]
        T_A = T_A, [description = "Governor high frequency cutoff time constant"]
        T_W = T_W, [description = "Water inertia time constant, sec"]
        T_B = T_B, [description = "Gate servo time constant"]
        VELMX = VELMX, [description = "Max gate opening velocity"]
        VELMN = VELMN, [description = "Min gate opening velocity"]
        GATMX = GATMX, [description = "Maximum gate velocity, pu of mwcap"]
        GATMN = GATMN, [description = "Minimum gate velocity, pu of mwcap"]
        PMAX = PMAX, [description = "Maximum gate opening, pu of mwcap"]
        PMIN = PMIN, [description = "Minimum gate opening, pu of mwcap"]
        D = D, [description = "Turbine damping coefficient"]
        G0 = G0, [description = "Gate opening at speed no load, pu"]
        G1 = G1, [description = "Intermediate gate opening"]
        G2 = G2, [description = "Intermediate gate opening"]
        P1 = P1, [description = "Power at gate opening G1, pu"]
        P2 = P2, [description = "Power at gate opening G2, pu"]
        P3 = P3, [description = "Power at full opened gate, pu"]
        PREF, [guess = 1.0]
        s00, [guess = 0.0]
        p0, [guess = 1.0]
        PMECH0, [guess = 1.0]
        s01, [guess = 0.0]
        s02, [guess = 0.0]
        sG, [guess = 0.5]
    end
    systems = @named begin
        add1 = Add(; k1 = -1)
        const_ = Constant(; k = PREF)
        simpleLag = SimpleLag(; K = n.REG, T = n.T_REG, y_start = s01)
        add3_1 = Add3()
        gain = Gain(; k = n.K_P)
        integrator = Integrator(; k = n.K_I, initType = :InitialOutput, y_start = 0)
        derivative = Derivative(; k = n.K_D, initType = :InitialOutput, x_start = s01)
        add3 = Add(; k1 = -1)
        simpleLag1 = SimpleLag(; K = 1, T = n.T_A, y_start = s02)
        simpleLag2 = SimpleLag(; K = 1, T = n.T_A, y_start = s02)
        derivativeLag = DerivativeLag(; K = 1, T = n.T_B, y_start = 0, x_start = s02)
        limiter = Limiter(; uMax = n.VELMX, uMin = n.VELMN)
        integrator1 = Integrator(; initType = :InitialOutput, y_start = sG)
        limiter1 = Limiter(; uMax = n.GATMX, uMin = n.GATMN)
        combiTable1Ds = CombiTable1Ds(; table = tbl, smoothness = :LinearSegments)
        leadLag1 = LeadLag(; K = 1, T1 = -n.T_W, T2 = n.T_W / 2, y_start = p0, x_start = 0)
        add2 = Add(; k1 = -1)
        gain1 = Gain(; k = n.D)
        limiter2 = Limiter(; uMax = n.PMAX, uMin = n.PMIN)
    end
    vars = @variables begin
        SPEED(t), [description = "Machine speed deviation from nominal [pu]"]
        PELEC(t), [description = "Machine electrical power [pu]"]
        PMECH(t), [description = "Turbine mechanical power [pu]"]
    end
    eqs = Equation[
        PELEC ~ add1.u2,                    # connect(PELEC, add1.u2)
        add1.y ~ simpleLag.u,               # connect(add1.y, simpleLag.u)
        const_.y ~ add1.u1,                 # connect(const.y, add1.u1)
        simpleLag.y ~ add3.u2,              # connect(simpleLag.y, add3.u2)
        SPEED ~ add3.u1,                    # connect(SPEED, add3.u1)
        add3.y ~ gain.u,                    # connect(add3.y, gain.u)
        integrator.u ~ gain.u,              # connect(integrator.u, gain.u)
        derivative.u ~ gain.u,              # connect(derivative.u, gain.u)
        integrator.y ~ add3_1.u2,           # connect(integrator.y, add3_1.u2)
        gain.y ~ add3_1.u1,                 # connect(gain.y, add3_1.u1)
        derivative.y ~ add3_1.u3,           # connect(derivative.y, add3_1.u3)
        add3_1.y ~ simpleLag1.u,            # connect(add3_1.y, simpleLag1.u)
        simpleLag2.y ~ derivativeLag.u,     # connect(simpleLag2.y, derivativeLag.u)
        simpleLag1.y ~ simpleLag2.u,        # connect(simpleLag1.y, simpleLag2.u)
        derivativeLag.y ~ limiter.u,        # connect(derivativeLag.y, limiter.u)
        limiter.y ~ integrator1.u,          # connect(limiter.y, integrator1.u)
        integrator1.y ~ limiter1.u,         # connect(integrator1.y, limiter1.u)
        limiter1.y ~ combiTable1Ds.u,       # connect(limiter1.y, combiTable1Ds.u)
        combiTable1Ds.y[1] ~ leadLag1.u,    # connect(combiTable1Ds.y[1], leadLag1.u)
        leadLag1.y ~ limiter2.u,            # connect(leadLag1.y, limiter2.u)
        limiter2.y ~ add2.u2,               # connect(limiter2.y, add2.u2)
        gain1.y ~ add2.u1,                  # connect(gain1.y, add2.u1)
        gain1.u ~ add3.u1,                  # connect(gain1.u, add3.u1)
        add2.y ~ PMECH,                     # connect(add2.y, PMECH)
    ]
    ieqs = [
        PREF ~ PELEC,
        PMECH0 ~ PELEC,
        p0 ~ PMECH0,
        s00 ~ PELEC - PREF,
        s01 ~ s00 * REG,
        s02 ~ s01 * K_P,
        sG ~ ifelse(p0 > P2, (p0 - P2) * (1 - G2) / (P3 - P2) + G2,
            ifelse(p0 < P1, p0 * (G1 - G0) / P1 + G0, (p0 - P1) * (G2 - G1) / (P2 - P1) + G1)),
    ]
    System(eqs, t, vars, pars; name, systems, initialization_eqs = ieqs,
        initial_conditions = Dict(PREF => missing, s00 => missing, p0 => missing, PMECH0 => missing,
            s01 => missing, s02 => missing, sG => missing))
end
