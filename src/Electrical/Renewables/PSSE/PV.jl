# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Renewables/PSSE/PV.mo (extends Electrical/Essentials/pfComponent.mo)
# Framework for a photovoltaic plant: three `replaceable` components over their partial bases (`BaseREGC`,
# `BaseREECB`, `BaseREPC`), selected with the `mods` keyword and the package's `redeclared`/`modified` helpers, as
# `Plant.jl` does. Without the three redeclares it does not compile, exactly as in Modelica.
#
# **The MLS 7.3.2 merge.** Unlike `Plant`, this template's Tests and cases depend on the modifiers of the
# `replaceable` *declaration* (`V_b`, `M_b`, `P_0`, `Q_0`, `v_0`, `angle_0` on the generator and the plant
# controller; `pfflag`, `vflag`, `qflag`, `pqflag = false` on the controller; `fflag`, `refflag` on the plant
# controller) surviving the `redeclare`, which brings only its own (`Tg = 0.017`, ...). That is MLS 3.4 section
# 7.3.2: the declaration's modifiers are merged with the `redeclare`'s, which takes precedence. `modified` is NOT
# changed -- its current rule (with a `redeclare`, only `S_b`/`fn` survive) is what the `VoltageSourceReImInputVary*`
# Tests need -- so the template writes its declaration modifiers as its own `NamedTuple` and merges them **below**
# the `redeclare`'s with `merge`, which gives precedence to the last argument, i.e. to the redeclare.
#
# **Conditional components and the flags.** `QFunctionality`, `PFunctionality` and `Irr2Pow` are Integer/Boolean
# parameters, so the five derived flags and the whole component selection are decided in Julia (F-50):
#   pfflag = QFunctionality == 0,  vflag = QFunctionality in (3, 6, 7),  qflag = QFunctionality in (2, 3, 6, 7),
#   refflag = QFunctionality in (5, 7),  fflag = PFunctionality == 1.
# With `QFunctionality >= 4` the `PlantController`, `freq_ref = Constant(k = fn)` and the four inputs `FREQ`,
# `branch_ir/ii`, `regulate_vr/vi` exist; with `< 4` the two gains `gain`/`gain1 = Gain(1)` carry `p_0 -> Pref` and
# `q_0 -> Qext` instead. `Irr2Pow` adds the input `i2p` and `gain2`/`gain3`/`gain4`. A component that does not exist
# is simply not put in `systems`, and its equations are not written: no case of OpenIPSL instantiates both branches.
# `M_b = RenewableGenerator.SysData.S_b` (sic, through the child's `outer`) is `M_b = S_b`.
# `fn` is a keyword argument although `enablefn = false`, because `freq_ref` reads `SysData.fn`.
# The causal connects are equalities; `connect(RenewableGenerator.p, pwPin)` stays a `connect`.
# Omitted: displayPF, graphical annotations, the Documentation section.

@component function PV(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        M_b = nothing, QFunctionality = 0, PFunctionality = 0, Irr2Pow = false, mods = (;))
    S_b, V_b, fn, P_0, Q_0, v_0, angle_0 = float.((S_b, V_b, fn, P_0, Q_0, v_0, angle_0))
    M_b = M_b === nothing ? S_b : float(M_b)
    # the five protected flags of the .mo, decided in Julia (F-50)
    pfflag = QFunctionality == 0
    vflag = QFunctionality in (3, 6, 7)
    qflag = QFunctionality in (2, 3, 6, 7)
    refflag = QFunctionality in (5, 7)
    fflag = PFunctionality == 1
    plant = QFunctionality >= 4
    base = pfComponent(; name, S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    @named pwPin = PwPin()
    # the modifiers of each `replaceable` declaration, merged UNDER the redeclare's (MLS 7.3.2, header)
    gen_decl = (; S_b, fn, V_b, M_b, P_0, Q_0, v_0, angle_0)
    ctrl_decl = (; pfflag, vflag, qflag, pqflag = false)
    repc_decl = (; S_b, fn, V_b, M_b, P_0, Q_0, v_0, angle_0, fflag, refflag)
    RenewableGenerator = redeclared(mods, :RenewableGenerator, BaseREGC)(; name = :RenewableGenerator,
        merge(gen_decl, modified(mods, :RenewableGenerator, (;)))...)
    RenewableController = redeclared(mods, :RenewableController, BaseREECB)(; name = :RenewableController,
        merge(ctrl_decl, modified(mods, :RenewableController, (;)))...)
    systems = [RenewableGenerator, RenewableController, pwPin]
    eqs = Equation[
        RenewableController.Iqcmd ~ RenewableGenerator.Iqcmd,
        RenewableGenerator.IQ0 ~ RenewableController.iq0,
        RenewableGenerator.IP0 ~ RenewableController.ip0,
        RenewableGenerator.V_0 ~ RenewableController.v0,
        RenewableGenerator.q_0 ~ RenewableController.q0,
        RenewableGenerator.p_0 ~ RenewableController.p0,
        RenewableGenerator.V_t ~ RenewableController.Vt,
        RenewableGenerator.Pgen ~ RenewableController.Pe,
        RenewableGenerator.Qgen ~ RenewableController.Qgen,
        RenewableController.Ipcmd ~ RenewableGenerator.Ipcmd,
        connect(RenewableGenerator.p, pwPin),
    ]
    vars = Any[]
    if plant
        PlantController = redeclared(mods, :PlantController, BaseREPC)(; name = :PlantController,
            merge(repc_decl, modified(mods, :PlantController, (;)))...)
        @named freq_ref = Constant(; k = fn)
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
            PlantController.Qref ~ RenewableGenerator.q_0,
            PlantController.Freq ~ FREQ,
            PlantController.branch_ii ~ branch_ii,
            PlantController.branch_ir ~ branch_ir,
            PlantController.regulate_vr ~ regulate_vr,
            PlantController.regulate_vi ~ regulate_vi,
        ])
        if !Irr2Pow
            @named gain4 = Gain(; k = 1)
            push!(systems, gain4)
            append!(eqs, Equation[gain4.u ~ RenewableGenerator.p_0, gain4.y ~ PlantController.Plant_pref])
        end
    else
        @named gain1 = Gain(; k = 1)
        push!(systems, gain1)
        append!(eqs, Equation[gain1.u ~ RenewableGenerator.q_0, gain1.y ~ RenewableController.Qext])
        if !Irr2Pow
            @named gain = Gain(; k = 1)
            push!(systems, gain)
            append!(eqs, Equation[gain.u ~ RenewableGenerator.p_0, gain.y ~ RenewableController.Pref])
        end
    end
    if Irr2Pow
        i2p = only(@variables i2p(t), [description = "Irradiance-derived power"])
        push!(vars, i2p)
        if plant
            @named gain3 = Gain(; k = 1)
            push!(systems, gain3)
            append!(eqs, Equation[gain3.u ~ i2p, gain3.y ~ PlantController.Plant_pref])
        else
            @named gain2 = Gain(; k = 1)
            push!(systems, gain2)
            append!(eqs, Equation[gain2.u ~ i2p, gain2.y ~ RenewableController.Pref])
        end
    end
    extend(System(eqs, t, vars, []; name, systems), base)
end
