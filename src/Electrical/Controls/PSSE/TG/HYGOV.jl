# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/TG/HYGOV.mo (extends TG/BaseClasses/BaseGovernor.mo)
# Blocks: n_ref = Constant(nref), SimpleLag1 = SimpleLag(1, T_f, 0), Gain3 = Gain(R), Gain4 = Gain(D_turb),
# hs = Constant(h0), q = Integrator(k = 1/T_w, InitialOutput, y_start = q0), qNL = Constant(q_NL), Gain6 = Gain(A_t),
# g = SimpleLag(1, T_g, y_start = g0), Velocity_Limiter = Limiter(+-VELM), Position_Limiter = LimIntegrator(k = 1,
# G_MAX, G_MIN, InitialOutput, y_start = c0), add/add1/add2/add3/add4 = Add, division = Division,
# product/product1/product2 = Product, simpleLead = SimpleLead(K = r*T_r, T = T_r, y_start = 0).
# The four display variables G, c, Q, H are plain variables with their defining equations. The causal connects are
# equalities.
# Five `parameter (fixed = false)` set by an `initial algorithm` (`P_m0 := PMECH0; q0 := P_m0/(A_t*h0) + q_NL;
# g0 := q0/sqrt(h0); c0 := g0; nref := R*c0`), a sequence of assignments transcribed as equalities in the same order.
# The chain starts from an input, so all five are declared with a guess, listed as `missing` in `initial_conditions`
# and given their equations in `initialization_eqs` (F-33), and they reach `n_ref`, `q`, `g` and `Position_Limiter`
# symbolically (F-38). `e0` is a plain parameter the `.mo` never uses.
# Omitted: Icons.VerifiedModel, graphical annotations.

@component function HYGOV(; name, R = 0.05, r = 0.3, T_r = 5, T_f = 0.05, T_g = 0.5, VELM = 0.2, G_MAX = 0.9,
        G_MIN = 0, T_w = 1.25, A_t = 1.2, D_turb = 0.2, q_NL = 0.08, h0 = 1)
    R, r, T_r, T_f, T_g, VELM, G_MAX, G_MIN, T_w, A_t, D_turb, q_NL, h0 =
        float.((R, r, T_r, T_f, T_g, VELM, G_MAX, G_MIN, T_w, A_t, D_turb, q_NL, h0))
    n = (; R, r, T_r, T_f, T_g, VELM, G_MAX, G_MIN, T_w, A_t, D_turb, q_NL, h0)   # numeric copies (F-22)
    @named base = BaseGovernor()
    @unpack SPEED, PMECH0, PMECH = base
    pars = @parameters begin
        R = R, [description = "Permanent droop gain"]
        r = r, [description = "Temporary droop gain"]
        T_r = T_r, [description = "Governor time constant"]
        T_f = T_f, [description = "Filter time constant"]
        T_g = T_g, [description = "Servo time constant"]
        VELM = VELM, [description = "Gate open/close velocity limit"]
        G_MAX = G_MAX, [description = "Maximum gate limit"]
        G_MIN = G_MIN, [description = "Minimum gate limit"]
        T_w = T_w, [description = "Water time constant"]
        A_t = A_t, [description = "Turbine gain"]
        D_turb = D_turb, [description = "Turbine damping"]
        q_NL = q_NL, [description = "Water flow at no load"]
        h0 = h0, [description = "Water head initial value > 0"]
        q0, [guess = 1.0]
        g0, [guess = 1.0]
        c0, [guess = 1.0]
        e0 = 0.0, [description = "initial output for the filter"]
        nref, [guess = 1.0]
        P_m0, [guess = 1.0]
    end
    systems = @named begin
        n_ref = Constant(; k = nref)
        SimpleLag1 = SimpleLag(; K = 1, T = n.T_f, y_start = 0)
        Gain3 = Gain(; k = n.R)
        Gain4 = Gain(; k = n.D_turb)
        hs = Constant(; k = n.h0)
        q = Integrator(; y_start = q0, initType = :InitialOutput, k = 1 / n.T_w)
        qNL = Constant(; k = n.q_NL)
        Gain6 = Gain(; k = n.A_t)
        g = SimpleLag(; K = 1, T = n.T_g, y_start = g0)
        Velocity_Limiter = Limiter(; uMin = -n.VELM, uMax = n.VELM)
        Position_Limiter = LimIntegrator(; outMin = n.G_MIN, outMax = n.G_MAX, k = 1, y_start = c0,
            initType = :InitialOutput)
        add = Add(; k2 = -1)
        add1 = Add()
        division = Division()
        product = Product()
        add2 = Add(; k1 = -1)
        add3 = Add(; k2 = -1)
        add4 = Add(; k2 = -1)
        product1 = Product()
        product2 = Product()
        simpleLead = SimpleLead(; K = n.r * n.T_r, T = n.T_r, y_start = 0)
    end
    vars = @variables begin
        G(t), [description = "Gate opening"]
        c(t), [description = "Desired gate opening"]
        Q(t), [description = "Turbine flow"]
        H(t), [description = "Turbine head"]
    end
    eqs = Equation[
        G ~ g.y,
        c ~ g.u,
        Q ~ q.y,
        H ~ product.y,
        add.y ~ SimpleLag1.u,                   # connect(add.y, SimpleLag1.u)
        n_ref.y ~ add.u1,                       # connect(n_ref.y, add.u1)
        add1.y ~ add.u2,                        # connect(add1.y, add.u2)
        Gain3.y ~ add1.u2,                      # connect(Gain3.y, add1.u2)
        Velocity_Limiter.y ~ Position_Limiter.u,# connect(Velocity_Limiter.y, Position_Limiter.u)
        Position_Limiter.y ~ Gain3.u,           # connect(Position_Limiter.y, Gain3.u)
        g.u ~ Gain3.u,                          # connect(g.u, Gain3.u)
        division.y ~ product.u1,                # connect(division.y, product.u1)
        product.u2 ~ product.u1,                # connect(product.u2, product.u1)
        product.y ~ add2.u1,                    # connect(product.y, add2.u1)
        hs.y ~ add2.u2,                         # connect(hs.y, add2.u2)
        add2.y ~ q.u,                           # connect(add2.y, q.u)
        q.y ~ add3.u1,                          # connect(q.y, add3.u1)
        qNL.y ~ add3.u2,                        # connect(qNL.y, add3.u2)
        Gain4.y ~ product1.u2,                  # connect(Gain4.y, product1.u2)
        product1.y ~ add4.u2,                   # connect(product1.y, add4.u2)
        product1.u1 ~ g.y,                      # connect(product1.u1, g.y)
        division.u2 ~ g.y,                      # connect(division.u2, g.y)
        division.u1 ~ add3.u1,                  # connect(division.u1, add3.u1)
        Gain6.y ~ add4.u1,                      # connect(Gain6.y, add4.u1)
        product2.y ~ Gain6.u,                   # connect(product2.y, Gain6.u)
        add3.y ~ product2.u2,                   # connect(add3.y, product2.u2)
        product2.u1 ~ add2.u1,                  # connect(product2.u1, add2.u1)
        simpleLead.y ~ Velocity_Limiter.u,      # connect(simpleLead.y, Velocity_Limiter.u)
        simpleLead.u ~ SimpleLag1.y,            # connect(simpleLead.u, SimpleLag1.y)
        add4.y ~ PMECH,                         # connect(add4.y, PMECH)
        SPEED ~ add1.u1,                        # connect(SPEED, add1.u1)
        Gain4.u ~ add1.u1,                      # connect(Gain4.u, add1.u1)
    ]
    ieqs = [P_m0 ~ PMECH0, q0 ~ P_m0 / (A_t * h0) + q_NL, g0 ~ q0 / sqrt(h0), c0 ~ g0, nref ~ R * c0]
    extend(System(eqs, t, vars, pars; name, systems, initialization_eqs = ieqs,
        initial_conditions = Dict(q0 => missing, g0 => missing, c0 => missing, nref => missing, P_m0 => missing)), base)
end
