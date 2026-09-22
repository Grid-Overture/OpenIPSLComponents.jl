# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Renewables/PSSE/Wind.mo (extends Electrical/Essentials/pfComponent.mo)
# Framework for a wind plant: **four** `replaceable` components (`BaseREGC`, `BaseREECA`, `BaseREPC` and the drive
# train `BaseWTDT`) with the same MLS 7.3.2 merge and the same Julia-level flag decisions as `PV.jl` -- see that
# file's header. Differences from `PV`:
#   * the fifth flag `pflag = TOscillation == 1`, passed to the electrical controller;
#   * the drive train, with `W0` (the initial slip, a required parameter here) and the `w0 = Constant(k = W0)`
#     that feeds its `W_0` input;
#   * `Wind` does **not** pass `V_b` to its generator (sic: `enableV_b = false` and the `replaceable` declaration
#     carries no `V_b` modifier, unlike `PV` and `BESS`), so the generator keeps its own default unless a
#     `redeclare` sets it;
#   * `Plant_pref` is wired straight to `p_0` (no `gain4`), as in `BESS`, and there is no `Irr2Pow` branch.
# Omitted: displayPF, graphical annotations, the Documentation section.

@component function Wind(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        M_b = nothing, QFunctionality = 0, PFunctionality = 0, TOscillation = 0, W0, mods = (;))
    S_b, V_b, fn, P_0, Q_0, v_0, angle_0, W0 = float.((S_b, V_b, fn, P_0, Q_0, v_0, angle_0, W0))
    M_b = M_b === nothing ? S_b : float(M_b)
    pfflag = QFunctionality == 0
    vflag = QFunctionality in (3, 6, 7)
    qflag = QFunctionality in (2, 3, 6, 7)
    refflag = QFunctionality in (5, 7)
    fflag = PFunctionality == 1
    pflag = TOscillation == 1
    plant = QFunctionality >= 4
    base = pfComponent(; name, S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    @named pwPin = PwPin()
    @named w0 = OpenIPSLComponents.Constant(; k = W0)
    gen_decl = (; S_b, fn, M_b, P_0, Q_0, v_0, angle_0)          # no V_b here (sic)
    ctrl_decl = (; pfflag, vflag, qflag, pflag)
    repc_decl = (; S_b, fn, M_b, P_0, Q_0, v_0, angle_0, fflag, refflag)
    dt_decl = (; S_b, fn, W0)
    RenewableGenerator = redeclared(mods, :RenewableGenerator, BaseREGC)(; name = :RenewableGenerator,
        merge(gen_decl, modified(mods, :RenewableGenerator, (;)))...)
    RenewableController = redeclared(mods, :RenewableController, BaseREECA)(; name = :RenewableController,
        merge(ctrl_decl, modified(mods, :RenewableController, (;)))...)
    DriveTrain = redeclared(mods, :DriveTrain, BaseWTDT)(; name = :DriveTrain,
        merge(dt_decl, modified(mods, :DriveTrain, (;)))...)
    systems = [RenewableGenerator, RenewableController, DriveTrain, pwPin, w0]
    eqs = Equation[
        connect(RenewableGenerator.p, pwPin),
        RenewableController.Iqcmd ~ RenewableGenerator.Iqcmd,
        RenewableController.Ipcmd ~ RenewableGenerator.Ipcmd,
        RenewableGenerator.V_t ~ RenewableController.Vt,
        RenewableGenerator.Pgen ~ RenewableController.Pe,
        RenewableGenerator.Qgen ~ RenewableController.Qgen,
        RenewableGenerator.IQ0 ~ RenewableController.iq0,
        RenewableGenerator.IP0 ~ RenewableController.ip0,
        RenewableGenerator.V_0 ~ RenewableController.v0,
        RenewableController.q0 ~ RenewableGenerator.q_0,
        RenewableController.p0 ~ RenewableGenerator.p_0,
        DriveTrain.wg ~ RenewableController.Wg,
        DriveTrain.Pe ~ RenewableGenerator.Pgen,
        DriveTrain.Pm ~ RenewableGenerator.p_0,
        DriveTrain.P0 ~ RenewableGenerator.p_0,
        w0.y ~ DriveTrain.W_0,
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
            freq_ref.y ~ PlantController.Freq_ref,
            PlantController.Plant_pref ~ RenewableGenerator.p_0,
            PlantController.Qref ~ RenewableGenerator.q_0,
            PlantController.Freq ~ FREQ,
            PlantController.Qext ~ RenewableController.Qext,
            PlantController.Pref ~ RenewableController.Pref,
            PlantController.q0 ~ RenewableController.q0,
            PlantController.v0 ~ RenewableController.v0,
            PlantController.p0 ~ RenewableController.p0,
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
