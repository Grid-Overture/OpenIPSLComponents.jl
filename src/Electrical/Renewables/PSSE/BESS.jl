# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Renewables/PSSE/BESS.mo (extends Electrical/Essentials/pfComponent.mo)
# Framework for a battery energy storage plant: the same three `replaceable` components as `PV.jl` (there over
# `BaseREECB`, here over `BaseREECC`) with the same MLS 7.3.2 merge and the same Julia-level flag decisions -- see
# `PV.jl`'s header, which this file follows exactly. Three differences from `PV`:
#   * `enablefn = true` (`PV` has it false and needs `fn` anyway for `freq_ref`; here it is declared useful);
#   * `PAUX = Constant(k = 0)` feeds `RenewableController.Paux`, which only `BaseREECC` has;
#   * there is no `Irr2Pow` branch, and `PlantController.Plant_pref` is wired straight to `RenewableGenerator.p_0`
#     instead of through a `gain4`.
# `gain`/`gain1` exist for `QFunctionality < 4` (note `gain` has no `and not Irr2Pow` guard here).
# Omitted: displayPF, graphical annotations, the Documentation section.

@component function BESS(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        M_b = nothing, QFunctionality = 0, PFunctionality = 0, mods = (;))
    S_b, V_b, fn, P_0, Q_0, v_0, angle_0 = float.((S_b, V_b, fn, P_0, Q_0, v_0, angle_0))
    M_b = M_b === nothing ? S_b : float(M_b)
    pfflag = QFunctionality == 0
    vflag = QFunctionality in (3, 6, 7)
    qflag = QFunctionality in (2, 3, 6, 7)
    refflag = QFunctionality in (5, 7)
    fflag = PFunctionality == 1
    plant = QFunctionality >= 4
    base = pfComponent(; name, S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    @named pwPin = PwPin()
    @named PAUX = OpenIPSLComponents.Constant(; k = 0)
    gen_decl = (; S_b, fn, V_b, M_b, P_0, Q_0, v_0, angle_0)
    ctrl_decl = (; pfflag, vflag, qflag, pqflag = false)
    repc_decl = (; S_b, fn, V_b, M_b, P_0, Q_0, v_0, angle_0, fflag, refflag)
    RenewableGenerator = redeclared(mods, :RenewableGenerator, BaseREGC)(; name = :RenewableGenerator,
        merge(gen_decl, modified(mods, :RenewableGenerator, (;)))...)
    RenewableController = redeclared(mods, :RenewableController, BaseREECC)(; name = :RenewableController,
        merge(ctrl_decl, modified(mods, :RenewableController, (;)))...)
    systems = [RenewableGenerator, RenewableController, pwPin, PAUX]
    eqs = Equation[
        RenewableController.Ipcmd ~ RenewableGenerator.Ipcmd,
        RenewableController.Iqcmd ~ RenewableGenerator.Iqcmd,
        RenewableGenerator.IQ0 ~ RenewableController.iq0,
        RenewableGenerator.IP0 ~ RenewableController.ip0,
        RenewableGenerator.V_0 ~ RenewableController.v0,
        RenewableGenerator.q_0 ~ RenewableController.q0,
        RenewableGenerator.p_0 ~ RenewableController.p0,
        RenewableGenerator.V_t ~ RenewableController.Vt,
        RenewableGenerator.Pgen ~ RenewableController.Pe,
        RenewableGenerator.Qgen ~ RenewableController.Qgen,
        connect(RenewableGenerator.p, pwPin),
        PAUX.y ~ RenewableController.Paux,
    ]
    vars = Any[]
    if plant
        PlantController = redeclared(mods, :PlantController, BaseREPC)(; name = :PlantController,
            merge(repc_decl, modified(mods, :PlantController, (;)))...)
        @named freq_ref = OpenIPSLComponents.Constant(; k = fn)
        push!(systems, PlantController, freq_ref)
        ports = @variables begin
            FREQ(t), [description = "Connection Point Frequency"]
            branch_ir(t), [description = "Measured Branch Real Current"]
            branch_ii(t), [description = "Measured Branch Imaginary Current"]
            regulate_vr(t), [description = "Regulated Branch Real Voltage"]
            regulate_vi(t), [description = "Regulated Branch Imaginary Voltage"]
        end
        append!(vars, ports)
        FREQ, branch_ir, branch_ii, regulate_vr, regulate_vi = ports
        append!(eqs, Equation[
            PlantController.Qext ~ RenewableController.Qext,
            PlantController.Pref ~ RenewableController.Pref,
            PlantController.p0 ~ RenewableController.p0,
            PlantController.v0 ~ RenewableController.v0,
            PlantController.q0 ~ RenewableController.q0,
            freq_ref.y ~ PlantController.Freq_ref,
            PlantController.Plant_pref ~ RenewableGenerator.p_0,
            PlantController.Qref ~ RenewableGenerator.q_0,
            PlantController.Freq ~ FREQ,
            PlantController.branch_ii ~ branch_ii,
            PlantController.branch_ir ~ branch_ir,
            PlantController.regulate_vr ~ regulate_vr,
            PlantController.regulate_vi ~ regulate_vi,
        ])
    else
        @named gain = Gain(; k = 1)
        @named gain1 = Gain(; k = 1)
        push!(systems, gain, gain1)
        append!(eqs, Equation[
            gain.u ~ RenewableGenerator.p_0,
            gain.y ~ RenewableController.Pref,
            gain1.u ~ RenewableGenerator.q_0,
            gain1.y ~ RenewableController.Qext,
        ])
    end
    extend(System(eqs, t, vars, []; name, systems), base)
end
