# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Solar/PowerFactory/DIgSILENT/PVArray.mo (extends nothing)
# Blocks, with the names of the .mo: gain = Gain(n_parallel), gain1 = Gain(n_series), module = PVModule(...,
# P_init = P_init/(n_parallel*n_series)) -- the instance is `module_` because `module` is a Julia keyword (rule 6.5,
# `JULIA_RENAMES`) --, module_time = FirstOrder(T = Tr, SteadyState), gain2 = Gain(1/n_series). Ports are plain
# variables (Uarray, the conditional E/theta; Iarray, Vmpp_array). `n_series`, `n_parallel` are Integers: converted
# with `float()` before `1/n_series` (F-21). Omitted: graphical annotations.

@component function PVArray(; name, P_init = nothing, n_series = 20, n_parallel = 140, Tr = 0.01, U0_stc = 43.8,
        Umpp_stc = 35, Impp_stc = 4.58, Isc_stc = 5, au = -0.0039, ai = 0.0004, use_input_E = false,
        use_input_theta = false)
    n_series, n_parallel, Tr = float.((n_series, n_parallel, Tr))
    U0_stc, Umpp_stc, Impp_stc, Isc_stc, au, ai = float.((U0_stc, Umpp_stc, Impp_stc, Isc_stc, au, ai))
    P_initn = P_init === nothing ? nothing : float(P_init)
    systems = @named begin
        gain = Gain(; k = n_parallel)
        gain1 = Gain(; k = n_series)
        module_ = PVModule(; Impp_stc, Isc_stc, P_init = P_initn === nothing ? nothing : P_initn / (n_parallel * n_series),
            U0_stc, Umpp_stc, ai, au, use_input_E, use_input_theta)
        module_time = FirstOrder(; T = Tr, initType = :SteadyState)
        gain2 = Gain(; k = 1 / n_series)
    end
    pars = @parameters begin
        P_init = (P_initn === nothing ? 0.0 : P_initn), [description = "Initial active power of the array (W)"]
        n_series = n_series, [description = "Number of modules in series"]
        n_parallel = n_parallel, [description = "Number of modules in parallel"]
        Tr = Tr, [description = "Time constant of modules (s)"]
        U0_stc = U0_stc, [description = "Open-circuit voltage at Standard Test Conditions (V)"]
        Umpp_stc = Umpp_stc, [description = "MPP voltage at Standard Test Conditions (V)"]
        Impp_stc = Impp_stc, [description = "MPP current at Standard Test Conditions (A)"]
        Isc_stc = Isc_stc, [description = "Short-circuit current at Standard Test Conditions (A)"]
        au = au, [description = "Temperature correction factor (voltage) (1/K)"]
        ai = ai, [description = "Temperature correction factor (current) (1/K)"]
    end
    vars = @variables begin
        Iarray(t), [description = "Array current (A)"]
        Vmpp_array(t), [description = "Array MPP voltage (V)"]
        Uarray(t), [description = "Array voltage input (V)"]
        E(t), [description = "Irradiance input (W/m2; only with use_input_E)"]
        theta(t), [description = "Temperature input (K; only with use_input_theta)"]
    end
    vars = [Iarray, Vmpp_array, Uarray, (use_input_E ? [E] : [])..., (use_input_theta ? [theta] : [])...]
    eqs = Equation[
        gain.y ~ Iarray,                 # connect(gain.y, Iarray)
        gain1.y ~ Vmpp_array,            # connect(gain1.y, Vmpp_array)
        module_time.u ~ Uarray,          # connect(module_time.u, Uarray)
        module_time.y ~ gain2.u,         # connect(module_time.y, gain2.u)
        gain2.y ~ module_.U,             # connect(gain2.y, module.U)
        module_.I ~ gain.u,              # connect(module.I, gain.u)
        module_.Umpp ~ gain1.u,          # connect(module.Umpp, gain1.u)
    ]
    use_input_E && push!(eqs, module_.E ~ E)             # if use_input_E then connect(module.E, E)
    use_input_theta && push!(eqs, module_.theta ~ theta) # if use_input_theta then connect(module.theta, theta)
    System(eqs, t, vars, pars; name, systems)
end
