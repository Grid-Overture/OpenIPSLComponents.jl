# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Branches/PSSE/TwoWindingTransformer.mo
# Julia name PSSE_TwoWindingTransformer (the PSAT transformer keeps the leaf name). Static PSS/E two-winding
# transformer without phase shift. The protected parameters (VNOM*_int, r, x, T1, T2, the complex t, Ym, xeq) are
# computed before `@parameters` with Julia complex arithmetic and kept as real pairs; the two complex equations
#   ej = ei/t + xeq*ij   and   (ii - ei*Ym)*conj(t) = -ij
# (ei, ii = pin p; ej, ij = pin n) are written as their real and imaginary parts, solved for ij and ej as the .mo
# has them (PLAN-02: Complex model variables as real pairs). SysData.S_b is the parameter S_b; fn (outer SystemBase)
# is accepted and unused. Its OpenIPSL Test instantiates GENSAL and is transcribed in batch 3 (PLAN-02).
# Omitted: graphical annotations.

@component function PSSE_TwoWindingTransformer(; name, S_b = 100e6, CZ = 1, R, X, G, B, CW = 1, t1 = 1, VNOM1 = 0, VB1 = 300e3,
        t2 = 1, VNOM2 = 0, VB2 = 300e3, ANG1 = 0, S_n = S_b, fn = 50)
    S_b, R, X, G, B, t1, VNOM1, VB1, t2, VNOM2, VB2, ANG1, S_n = float.((S_b, R, X, G, B, t1, VNOM1, VB1, t2, VNOM2, VB2, ANG1, S_n))
    VNOM1_int = abs(VNOM1) < Modelica.Constants.eps ? VB1 : VNOM1
    VNOM2_int = abs(VNOM2) < Modelica.Constants.eps ? VB2 : VNOM2
    r = CZ == 1 ? R : R * S_b / S_n
    x = CZ == 1 ? X : X * S_b / S_n
    T2 = CW == 1 ? t2 : CW == 3 ? t2 * (VNOM2_int / VB2) : t2 / VB2
    T1 = CW == 1 ? t1 : CW == 3 ? t1 * (VNOM1_int / VB1) : t1 / VB1
    tc = T1 / T2 * cis(ANG1)   # t = T1/T2*(cos(ANG1) + j*sin(ANG1))
    Ym = complex(G, B)
    xeq = complex(r * abs(T2)^2, x * abs(T2)^2)
    tr, ti, t2abs = real(tc), imag(tc), abs2(tc)
    xr, xi = real(xeq), imag(xeq)
    pars = @parameters begin
        S_b = S_b, [description = "System base power (VA)"]
        CZ = CZ, [description = "Impedance I/O code"]
        R = R, [description = "Specified R (pu)"]
        X = X, [description = "Specified X (pu)"]
        G = G, [description = "Magnetizing G (pu)"]
        B = B, [description = "Magnetizing B (pu)"]
        CW = CW, [description = "Winding I/O code"]
        t1 = t1, [description = "Ratio of winding 1 (pu)"]
        VNOM1 = VNOM1, [description = "Nominal voltage of winding 1 (V)"]
        VB1 = VB1, [description = "Bus base voltage of winding 1 (V)"]
        t2 = t2, [description = "Tap ratio of winding 2 (pu)"]
        VNOM2 = VNOM2, [description = "Nominal voltage of winding 2 (V)"]
        VB2 = VB2, [description = "Bus base voltage of winding 2 (V)"]
        ANG1 = ANG1, [description = "Winding (1-2) angle (rad)"]
        S_n = S_n, [description = "Nominal power of the winding (VA)"]
        VNOM1_int = VNOM1_int
        VNOM2_int = VNOM2_int
        r = r, [description = "Resistance (pu)"]
        x = x, [description = "Reactance (pu)"]
        T1 = T1
        T2 = T2
        t_re = tr, [description = "Complex ratio t, real part"]
        t_im = ti, [description = "Complex ratio t, imaginary part"]
        xeq_re = xr, [description = "Equivalent impedance, real part (pu)"]
        xeq_im = xi, [description = "Equivalent impedance, imaginary part (pu)"]
    end
    systems = @named begin
        p = PwPin()
        n = PwPin()
    end
    # (ii - ei*Ym)*conj(t) = -ij : ij = -((a + j b)(t_re - j t_im)) with a + j b = ii - ei*Ym
    a = p.ir - (G * p.vr - B * p.vi)
    b = p.ii - (B * p.vr + G * p.vi)
    eqs = Equation[
        n.ir ~ -(a * t_re + b * t_im),
        n.ii ~ -(b * t_re - a * t_im),
        # ej = ei/t + xeq*ij, 1/t = conj(t)/|t|^2
        n.vr ~ (p.vr * t_re + p.vi * t_im) / t2abs + xeq_re * n.ir - xeq_im * n.ii,
        n.vi ~ (p.vi * t_re - p.vr * t_im) / t2abs + xeq_re * n.ii + xeq_im * n.ir,
    ]
    System(eqs, t, [], pars; name, systems)
end
