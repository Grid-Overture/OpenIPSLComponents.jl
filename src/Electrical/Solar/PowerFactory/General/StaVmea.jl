# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Solar/PowerFactory/General/StaVmea.mo (extends nothing)
# Blocks: none. The PowerFactory voltage measurement device: `u = |v|` and the electrical frequency `fe` (in **pu**,
# although the .mo says Hz) obtained from the derivative of the voltage phasor through a lag `Tfe`.
# `use_ref_machine_frequency` is a Boolean parameter no user of OpenIPSL 3.1.0 sets: only the `false` branch is
# ported (F-50) -- `cosphi = vx/u`, `sinphi = vy/u`, `vx = p.vr`, `vy = p.vi`, `der(local_df_internal) = (df -
# local_df_internal)/Tfe`, `fe = 1 + local_df_internal`, `omega_internal = phi_internal = 0` ("Balance equation") --
# and `true` (the rotating frame of a reference machine, the conditional inputs `omega`/`phi`) is refused.
# `if abs(cosphi) > abs(sinphi) then df = der(sinphi)/cosphi/(2 pi fn) else df = -der(cosphi)/sinphi/(2 pi fn)` is
# an `ifelse` on **derivatives of network algebraics**: ModelingToolkit's index reduction differentiates the chain
# down to the states of the source (`phiu` of `ElmVac`), the compiled system keeps two states and the dead branch
# (a 0/0 at `sinphi = 0`) does not contaminate the live one (PLAN-08 probe 0.1, F-71). `local_df_internal` is a
# protected `RealInput` with no `start` that becomes a state: OpenModelica fixes it at 0, an `initial_conditions`
# entry here; the `start` of `cosphi`, `sinphi`, `df` are guesses. `p.ii = p.ir = 0`: the sensor draws no current.
# Omitted: graphical annotations.

@component function StaVmea(; name, Tfe = 3 / 50, fn = 50, angle_0 = 0, use_ref_machine_frequency = false)
    use_ref_machine_frequency && error("StaVmea: use_ref_machine_frequency = true is not ported (F-50)")
    Tfe, fn, angle_0 = float.((Tfe, fn, angle_0))
    pars = @parameters begin
        Tfe = Tfe, [description = "Measurement delay (s)"]
        fn = fn, [description = "Nominal frequency (Hz)"]
        angle_0 = angle_0, [description = "Initial angle (rad)"]
    end
    systems = @named begin
        p = PwPin()
    end
    vars = @variables begin
        cosphi(t)
        sinphi(t)
        df(t), [description = "Frequency difference"]
        vx(t), [description = "Voltage component"]
        vy(t), [description = "Voltage component"]
        u(t), [description = "Voltage magnitude (pu)"]
        fe(t), [description = "Electrical frequency (pu; the .mo says Hz)"]
        omega_internal(t), [description = "Helping variable/connector"]
        phi_internal(t), [description = "Helping variable/connector"]
        local_df_internal(t), [description = "Helping variable/connector"]
    end
    eqs = Equation[
        u ~ sqrt(p.vr^2 + p.vi^2),
        cosphi ~ vx / u,
        sinphi ~ vy / u,
        der(local_df_internal) ~ (df - local_df_internal) / Tfe,
        vx ~ p.vr,
        vy ~ p.vi,
        fe ~ 1 + local_df_internal,
        omega_internal ~ 0,   # "Balance equation"
        phi_internal ~ 0,     # "Balance equation"
        df ~ ifelse(abs(cosphi) > abs(sinphi), der(sinphi) / cosphi / (2 * pi * fn), -der(cosphi) / sinphi / (2 * pi * fn)),
        p.ii ~ 0,
        p.ir ~ 0,
    ]
    System(eqs, t, vars, pars; name, systems, initial_conditions = Dict(local_df_internal => 0.0),
        guesses = Dict(cosphi => cos(angle_0), sinphi => sin(angle_0), df => 0.0))
end
