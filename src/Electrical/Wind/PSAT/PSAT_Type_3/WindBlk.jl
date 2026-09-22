# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Wind/PSAT/PSAT_Type_3/WindBlk.mo (extends nothing)
# Blocks: none. Ports are plain variables (vw, theta_p, omega_m; Tm). Purely algebraic: the tip-speed ratio, the
# Heier/PSAT power coefficient `cp = 0.22*(116/lambdai - 0.4*theta_p - 5)*exp(-12.5/lambdai)` and the torque.
# `Radapt = ngb*l`, `wbase = 2*pi*freq` (its own; PSAT_WT overrides it with 2*pi*fn/poles) and `Ar = pi*l^2` are
# the derived parameters; `poles` is declared and unused (sic). Omitted: the `import`, graphical annotations.

@component function WindBlk(; name, vw_base = 15, rho = 1.225, Sbase = 100000000, l = 75, ngb = 0.01123596,
        Radapt = ngb * l, poles = 2, freq = 50, wbase = 2 * pi * freq, Ar = pi * l^2)
    vw_base, rho, Sbase, l, ngb, Radapt, freq, wbase, Ar = float.((vw_base, rho, Sbase, l, ngb, Radapt, freq, wbase, Ar))
    pars = @parameters begin
        vw_base = vw_base, [description = "Vw Nominal (m/s)"]
        rho = rho, [description = "Air Density (kg/m3)"]
        Sbase = Sbase, [description = "Power Rating [Normalization Factor] (VA)"]
        l = l, [description = "Blade length (m)"]
        ngb = ngb, [description = "gear box ratio"]
        Radapt = Radapt, [description = "r_{gearbox}*r"]
        poles = poles, [description = "Number of poles-pair (unused)"]
        freq = freq, [description = "frequency rating (Hz)"]
        wbase = wbase, [description = "base angular speed (rad/s)"]
        Ar = Ar, [description = "blades area (m2)"]
    end
    vars = @variables begin
        vw(t), [description = "Wind speed (pu of vw_base)"]
        theta_p(t), [description = "Pitch angle"]
        omega_m(t), [description = "Mechanical speed"]
        Tm(t), [description = "Mechanical torque"]
        lambda(t), [description = "Tip speed Ratio"]
        lambdai(t), [description = "Tip Speed Ratio optimal"]
        cp(t), [description = "Capacity coefficient"]
        Pw(t), [description = "Power in the Wind"]
    end
    eqs = Equation[
        lambda ~ omega_m * wbase * Radapt / (vw * vw_base),
        lambdai ~ 1 / (1 / (lambda + 0.08 * theta_p) - 0.035 / (theta_p^3 + 1)),
        cp ~ 0.22 * (116 / lambdai - 0.4 * theta_p - 5) * exp(-12.5 / lambdai),
        Pw ~ 0.5 * rho * cp * Ar * (vw * vw_base)^3 / Sbase,
        Tm ~ Pw / omega_m,
    ]
    System(eqs, t, vars, pars; name)
end
