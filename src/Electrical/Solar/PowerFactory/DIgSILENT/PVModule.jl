# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Solar/PowerFactory/DIgSILENT/PVModule.mo (extends nothing)
# Blocks: not_use_input_theta = RealExpression(y = theta_STC) if not use_input_theta, not_use_input_E =
# RealExpression(y = P_init) if not use_input_E (conditional instances, created only in their branch). Ports are
# plain variables (U, the conditional E/theta; I, Umpp). The single-diode I-V curve of a module, every `if` on a
# variable an `ifelse` (sic, the .mo has no noEvent). `Modelica.Units.Conversions.to_degC(x)` is `x - 273.15`.
# With `use_input_E = false` the irradiance `local_E` has no equation of its own: it is the algebraic unknown that
# closes `P = Impp*Umpp = P_init` (monotone in E for E > 1, one root). The .mo's `initial equation der(local_E) = 0`
# only says that E is constant, which the constraint already gives, and an algebraic variable has no `der` in
# ModelingToolkit: it is not written. Julia-only, without changing an equation: the root `E0` is computed in the
# constructor by bisection and handed to the initialization as the **guess** of `local_E` (precedent F-34).
# Dead-branch note (F-04): `log(1 - Impp/Isc)` is a NaN when `E <= 1` (Isc = 0), inside the branch `ifelse` does not
# select; harmless in value (the Tests sit at E ~ 704 W/m2), watched by the hand test at E <= 1.
# Omitted: graphical annotations.

@component function PVModule(; name, U0_stc = 43.8, Umpp_stc = 35, Impp_stc = 4.58, Isc_stc = 5, au = -0.0039,
        ai = 0.0004, use_input_E = false, use_input_theta = false, P_init = nothing, E_STC = 1000, theta_STC = 298.15)
    use_input_E || P_init !== nothing || error("PVModule: P_init is required when use_input_E = false")
    U0_stc, Umpp_stc, Impp_stc, Isc_stc, au, ai, E_STC, theta_STC = float.((U0_stc, Umpp_stc, Impp_stc, Isc_stc, au, ai, E_STC, theta_STC))
    P_initn = use_input_E ? 0.0 : float(P_init)
    E0 = use_input_E ? E_STC : pvmodule_E0(P_initn, Umpp_stc, Impp_stc, E_STC, use_input_theta ? theta_STC : theta_STC, au, ai)
    theta_STCn = theta_STC
    pars = @parameters begin
        U0_stc = U0_stc, [description = "Open-circuit voltage at Standard Test Conditions (V)"]
        Umpp_stc = Umpp_stc, [description = "MPP voltage at Standard Test Conditions (V)"]
        Impp_stc = Impp_stc, [description = "MPP current at Standard Test Conditions (A)"]
        Isc_stc = Isc_stc, [description = "Short-circuit current at Standard Test Conditions (A)"]
        au = au, [description = "Temperature correction factor (voltage) (1/K)"]
        ai = ai, [description = "Temperature correction factor (current) (1/K)"]
        P_init = P_initn, [description = "Initial active power (W; needed only if input E is not used)"]
        E_STC = E_STC, [description = "Irradiance at Standard Test Conditions (W/m2)"]
        theta_STC = theta_STC, [description = "Temperature at Standard Test Conditions (K)"]
    end
    systems = System[]
    use_input_theta || push!(systems, RealExpression(; name = :not_use_input_theta, expr = theta_STCn))
    use_input_E || push!(systems, RealExpression(; name = :not_use_input_E, expr = P_initn))
    vars = @variables begin
        U(t), [description = "Module voltage input (V)"]
        E(t), [description = "Irradiance input (W/m2; only with use_input_E)"]
        theta(t), [description = "Temperature input (K; only with use_input_theta)"]
        I(t), [description = "Module current (A)"]
        Umpp(t), [description = "MPP voltage (V)"]
        U0(t), [description = "Open-circuit voltage (V)"]
        Isc(t), [description = "Short-circuit current (A)"]
        Impp(t), [description = "MPP Current (A)"]
        tempCorrU(t), [description = "Voltage Correction Factor"]
        tempCorrI(t), [description = "Current Correction Factor"]
        lnEquot(t), [description = "Logarithm of the irradiance ratio"]
        c1(t), [description = "Helper variable"]
        c2(t), [description = "Helper variable"]
        local_E(t), [description = "Irradiance (W/m2)"]
        local_theta(t), [description = "Temperature (K)"]
        P(t), [description = "Value of Real output"]
    end
    vars = [U, I, Umpp, U0, Isc, Impp, tempCorrU, tempCorrI, lnEquot, c1, c2, local_E, local_theta, P,
        (use_input_E ? [E] : [])..., (use_input_theta ? [theta] : [])...]
    eqs = Equation[
        tempCorrU ~ 1 + au * ((local_theta - 273.15) - 25),
        tempCorrI ~ 1 + ai * ((local_theta - 273.15) - 25),
        lnEquot ~ ifelse(local_E > 1.0, log(max(local_E, 1.0)) / log(E_STC), 0),
        U0 ~ U0_stc * lnEquot * tempCorrU,
        Isc ~ ifelse(local_E > 1, Isc_stc * local_E / E_STC * tempCorrI, 0),
        Umpp ~ Umpp_stc * lnEquot * tempCorrU,
        Impp ~ ifelse(local_E > 1, Impp_stc * local_E / E_STC * tempCorrI, 0),
        c1 ~ ifelse(U0 > 0, Umpp - U0, 1),
        c2 ~ ifelse(U0 > 0, ifelse(c1 < 0, log(1 - Impp / Isc) / c1, 0), 0),
        I ~ max(Isc * (1 - exp(c2 * (min(U0, U) - U0))), 0.0),
        P ~ Impp * Umpp,
    ]
    # connect(E, local_E); connect(not_use_input_E.y, P): the conditional connections of the .mo
    push!(eqs, use_input_E ? (E ~ local_E) : (systems[end].y ~ P))
    # connect(theta, local_theta); connect(not_use_input_theta.y, local_theta)
    push!(eqs, use_input_theta ? (theta ~ local_theta) : (systems[1].y ~ local_theta))
    System(eqs, t, vars, pars; name, systems, guesses = Dict(local_E => E0, local_theta => theta_STCn))
end

# The irradiance at which the module delivers P_init at its MPP, Impp(E)*Umpp(E) = P_init (E > 1, monotone):
# bisection on [1 + eps, 1e6] with the module's own expressions (temperature at theta_STC -> tempCorr = 1).
function pvmodule_E0(P_init, Umpp_stc, Impp_stc, E_STC, theta, au, ai)
    tcu = 1 + au * ((theta - 273.15) - 25)
    tci = 1 + ai * ((theta - 273.15) - 25)
    f(E) = (Impp_stc * E / E_STC * tci) * (Umpp_stc * log(E) / log(E_STC) * tcu) - P_init
    lo, hi = 1.0 + 1e-9, 1e6
    f(hi) < 0 && return hi
    for _ in 1:200
        mid = (lo + hi) / 2
        f(mid) < 0 ? (lo = mid) : (hi = mid)
    end
    (lo + hi) / 2
end
