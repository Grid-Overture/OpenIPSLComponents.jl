# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Wind/GE/Type_3/Generator/Generator.mo (extends nothing); the function is `GE_Generator`
# because `Interfaces.Generator` is `Generator` (rule 6.5, PLAN-08).
# Blocks, with the names of the .mo: the PLL integrator1 = Integrator(k = omega_0, y_start = ge_x2_0) driven by
# add1(k2 = -1) = Vt_im*cos - sin*Vt_re -> gain1 = Gain(Kpllp/omega_0) -> limiter1 = Limiter(+-0.1); cos1 = Cos,
# sin1 = Sin on the PLL angle; the two lags integrator2 = Integrator(1/0.01, ge_x0_0) (E, on Efd - E) and
# integrator3 = Integrator(1/0.01, ge_x1_0) (Ip, on Ipcmd - Ip); the current assembly gain4 = Gain(-1/Lpp), gain2,
# gain3 = Gain(1/Lpp), product1..6, add2..add7. Ports are plain variables (Efd, Ipcmd; Vt, Pgen, Qgen) and the pin
# `p`. `add7.y*GEN_base/SYS_base = -p.ir` and `add6.y*GEN_base/SYS_base = -p.ii` are written solved for the pin
# currents (a sign moved across: the pin currents were already explicit, F-16 does not apply).
# `Anglet = atan(Vt_im/Vt_re)` is `atan` of the quotient, not atan2, literal (it can jump during a fault).
# Omitted: the `import`, graphical annotations.

@component function GE_Generator(; name, freq = 50, Kpllp = 1, ge_x0_0 = 1, ge_x1_0 = 1, ge_x2_0 = 1, GEN_base = 1,
        SYS_base = 1, Lpp = 1)
    freq, Kpllp, ge_x0_0, ge_x1_0, ge_x2_0, GEN_base, SYS_base, Lpp = float.((freq, Kpllp, ge_x0_0, ge_x1_0, ge_x2_0, GEN_base, SYS_base, Lpp))
    omega_0 = 2 * pi * freq
    systems = @named begin
        p = PwPin()
        integrator1 = Integrator(; k = omega_0, y_start = ge_x2_0)
        limiter1 = Limiter(; uMax = 0.1, uMin = -0.1)
        gain1 = Gain(; k = Kpllp / omega_0)
        cos1 = Cos()
        sin1 = Sin()
        product1 = Product()
        product2 = Product()
        add1 = Add(; k2 = -1)
        gain2 = Gain(; k = 1 / Lpp)
        gain3 = Gain(; k = 1 / Lpp)
        integrator2 = Integrator(; k = 1 / 0.01, y_start = ge_x0_0)
        integrator3 = Integrator(; k = 1 / 0.01, y_start = ge_x1_0)
        add2 = Add(; k2 = -1)
        add3 = Add(; k2 = -1)
        gain4 = Gain(; k = -1 / Lpp)
        add4 = Add(; k2 = -1)
        product3 = Product()
        product4 = Product()
        product5 = Product()
        product6 = Product()
        add5 = Add()
        add6 = Add()
        add7 = Add(; k2 = -1)
    end
    pars = @parameters begin
        freq = freq, [description = "Frequency (Hz)"]
        omega_0 = omega_0, [description = "2*pi*freq (rad/s)"]
        Kpllp = Kpllp
        ge_x0_0 = ge_x0_0
        ge_x1_0 = ge_x1_0
        ge_x2_0 = ge_x2_0
        GEN_base = GEN_base, [description = "Generator base power (VA)"]
        SYS_base = SYS_base, [description = "System base power (VA)"]
        Lpp = Lpp
    end
    vars = @variables begin
        Efd(t), [description = "Excitation voltage"]
        Ipcmd(t), [description = "Current command"]
        Vt(t), [description = "Terminal voltage"]
        Pgen(t), [description = "Active power"]
        Qgen(t), [description = "Reactive power"]
        Anglet(t)
        Vt_re(t)
        Vt_im(t)
    end
    eqs = Equation[
        integrator2.y ~ gain4.u,                 # connect(integrator2.y, gain4.u)
        gain4.y ~ product5.u1,                   # connect(gain4.y, product5.u1)
        gain4.y ~ product3.u1,                   # connect(gain4.y, product3.u1)
        add3.u1 ~ Ipcmd,                         # connect(add3.u1, Ipcmd)
        Efd ~ add2.u1,                           # connect(Efd, add2.u1)
        gain2.y ~ add6.u2,                       # connect(gain2.y, add6.u2)
        add7.u1 ~ add4.y,                        # connect(add7.u1, add4.y)
        gain3.y ~ add7.u2,                       # connect(gain3.y, add7.u2)
        add6.u1 ~ add5.y,                        # connect(add6.u1, add5.y)
        integrator3.y ~ product6.u1,             # connect(integrator3.y, product6.u1)
        integrator3.y ~ product4.u1,             # connect(integrator3.y, product4.u1)
        product3.u2 ~ sin1.y,                    # connect(product3.u2, sin1.y)
        product6.u2 ~ sin1.y,                    # connect(product6.u2, sin1.y)
        product1.y ~ add1.u1,                    # connect(product1.y, add1.u1)
        product2.y ~ add1.u2,                    # connect(product2.y, add1.u2)
        cos1.y ~ product1.u2,                    # connect(cos1.y, product1.u2)
        sin1.y ~ product2.u1,                    # connect(sin1.y, product2.u1)
        add1.y ~ gain1.u,                        # connect(add1.y, gain1.u)
        cos1.y ~ product4.u2,                    # connect(cos1.y, product4.u2)
        cos1.y ~ product5.u2,                    # connect(cos1.y, product5.u2)
        product4.y ~ add4.u1,                    # connect(product4.y, add4.u1)
        product3.y ~ add4.u2,                    # connect(product3.y, add4.u2)
        product5.y ~ add5.u1,                    # connect(product5.y, add5.u1)
        product6.y ~ add5.u2,                    # connect(product6.y, add5.u2)
        integrator1.y ~ sin1.u,                  # connect(integrator1.y, sin1.u)
        integrator1.y ~ cos1.u,                  # connect(integrator1.y, cos1.u)
        gain1.y ~ limiter1.u,                    # connect(gain1.y, limiter1.u)
        limiter1.y ~ integrator1.u,              # connect(limiter1.y, integrator1.u)
        integrator3.y ~ add3.u2,                 # connect(integrator3.y, add3.u2)
        integrator2.y ~ add2.u2,                 # connect(integrator2.y, add2.u2)
        add3.y ~ integrator3.u,                  # connect(add3.y, integrator3.u)
        add2.y ~ integrator2.u,                  # connect(add2.y, integrator2.u)
        Vt_re ~ p.vr,
        Vt_im ~ p.vi,
        p.ir ~ -add7.y * GEN_base / SYS_base,    # add7.y*GEN_base/SYS_base = -p.ir
        p.ii ~ -add6.y * GEN_base / SYS_base,    # add6.y*GEN_base/SYS_base = -p.ii
        Vt ~ sqrt(Vt_re^2 + Vt_im^2),
        Anglet ~ atan(Vt_im / Vt_re),
        product1.u1 ~ Vt_im,
        product2.u2 ~ Vt_re,
        gain2.u ~ Vt_re,
        gain3.u ~ Vt_im,
        Pgen ~ Vt_re * add7.y + Vt_im * add6.y,
        Qgen ~ Vt_im * add7.y - Vt_re * add6.y,
    ]
    System(eqs, t, vars, pars; name, systems)
end
