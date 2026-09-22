# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Renewables/PSSE/PlantController/BaseClasses/BaseREPC.mo (partial)
# extends: Electrical/Essentials/pfComponent.mo (enablefn = enableV_b = false -- inert, kept as keyword arguments;
# `M_b = SysData.S_b` by default, i.e. M_b = S_b).
# Ports only: the three control flags, the eleven causal ports (Qref, Plant_pref, Freq, Freq_ref, p0, q0, v0,
# branch_ir, branch_ii, regulate_vr, regulate_vi inputs; Qext, Pref outputs) and the single protected parameter
# `CoB = M_b/S_b`. No equation.
# `vcflag`, `refflag` and `fflag` are Boolean parameters: they stay numeric keyword arguments here (the child
# instantiates the `BooleanConstant` blocks with them, F-50).
# Omitted: the `import Complex`/`ComplexMath` lines, displayPF, graphical annotations.

@component function BaseREPC(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        M_b = nothing)
    S_b, V_b, fn, P_0, Q_0, v_0, angle_0 = float.((S_b, V_b, fn, P_0, Q_0, v_0, angle_0))
    M_b = M_b === nothing ? S_b : float(M_b)
    base = pfComponent(; name, S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    pars = @parameters begin
        M_b = M_b, [description = "Machine base power (VA)"]
        CoB = M_b / S_b
    end
    vars = @variables begin
        Qref(t), [description = "Reactive Power Reference"]
        Plant_pref(t), [description = "Active Power Reference"]
        Freq(t), [description = "Connection Point Frequency"]
        Freq_ref(t), [description = "Plant Controller Frequency Reference"]
        Qext(t), [description = "Reactive Power output signal"]
        Pref(t), [description = "Real Power output signal"]
        p0(t), [description = "Initial Active Power"]
        q0(t), [description = "Initial Reactive Power"]
        v0(t), [description = "Initial Terminal Voltage Magnitude"]
        branch_ir(t), [description = "Measured Branch Real Current"]
        branch_ii(t), [description = "Measured Branch Imaginary Current"]
        regulate_vr(t), [description = "Regulated Branch Real Voltage"]
        regulate_vi(t), [description = "Regulated Branch Imaginary Voltage"]
    end
    extend(System(Equation[], t, vars, pars; name), base)
end
