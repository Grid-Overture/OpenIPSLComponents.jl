# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Solar/PowerFactory/DIgSILENT/Auxiliary/ReactivePowerSupport.mo (extends nothing)
# Blocks, with the names of the .mo: FRT_characteristic_selection = Switch + FRTCharac = BooleanConstant(i_EEG)
# (the `if` on a Boolean parameter instantiated literally, precedent `Lvplsw_logic`), limiter = Limiter(iq_max,
# iq_min), picdro = Picdro(Tdrop = if i_EEG then 0 else 0.5, Tpick = 0), **greaterEqualThreshold(threshold = 0)**
# on abs = Abs (instance `abs_`, a Base function) of deadZone = DeadZone(+-Deadband) -- `|deadZone.y| >= 0` is
# always true (sic): `picdro.condition = 1` from t = 0 and `trip = 1` from t = 1e-8 for the whole run, which the
# oracle of Tests.Solar.PowerFactory.DIgSILENT_PV confirms --, initial_current = Constant(i0), add, gain =
# Gain(K_FRT), switch, zero_FRT_support = Constant(0), switch1, sLDWindV = SLDWindV(Deadband, K_FRT). Ports are
# plain variables (duac; iq). Omitted: graphical annotations.

@component function ReactivePowerSupport(; name, iq_max, iq_min, i_EEG, Deadband, K_FRT, i0)
    iq_max, iq_min, Deadband, K_FRT, i0 = float.((iq_max, iq_min, Deadband, K_FRT, i0))
    pars = @parameters begin
        iq_max = iq_max, [description = "Maximum reactive current (pu)"]
        iq_min = iq_min, [description = "Minimum reactive current (pu)"]
        Deadband = Deadband, [description = "Deadband for dynamic AC voltage support (pu)"]
        K_FRT = K_FRT, [description = "Gain for dynamic AC voltage supports"]
        i0 = i0, [description = "Initial reactive current (pu)"]
    end
    systems = @named begin
        FRT_characteristic_selection = Switch()
        FRTCharac = BooleanConstant(; k = i_EEG)
        limiter = Limiter(; uMax = iq_max, uMin = iq_min)
        picdro = Picdro(; Tdrop = i_EEG ? 0.0 : 0.5, Tpick = 0.0)
        greaterEqualThreshold = GreaterEqualThreshold(; threshold = 0)
        abs_ = Abs()
        deadZone = DeadZone(; uMax = Deadband, uMin = -Deadband)
        initial_current = OpenIPSLComponents.Constant(; k = i0)
        add = Add()
        gain = Gain(; k = K_FRT)
        switch = Switch()
        zero_FRT_support = OpenIPSLComponents.Constant(; k = 0)
        switch1 = Switch()
        sLDWindV = SLDWindV(; Deadband, K_FRT)
    end
    vars = @variables begin
        duac(t), [description = "Voltage deviation (pu)"]
        iq(t), [description = "Reactive current reference (pu)"]
    end
    eqs = Equation[
        FRTCharac.y ~ FRT_characteristic_selection.u2,       # connect(FRTCharac.y, FRT_characteristic_selection.u2)
        limiter.y ~ iq,                                      # connect(limiter.y, iq)
        greaterEqualThreshold.u ~ abs_.y,                    # connect(greaterEqualThreshold.u, abs.y)
        greaterEqualThreshold.y ~ picdro.condition,          # connect(greaterEqualThreshold.y, picdro.condition)
        duac ~ deadZone.u,                                   # connect(duac, deadZone.u)
        deadZone.y ~ abs_.u,                                 # connect(deadZone.y, abs.u)
        FRT_characteristic_selection.y ~ add.u1,             # connect(FRT_characteristic_selection.y, add.u1)
        add.y ~ limiter.u,                                   # connect(add.y, limiter.u)
        initial_current.y ~ add.u2,                          # connect(initial_current.y, add.u2)
        gain.u ~ deadZone.y,                                 # connect(gain.u, deadZone.y)
        picdro.trip ~ switch.u2,                             # connect(picdro.trip, switch.u2)
        switch.u1 ~ gain.y,                                  # connect(switch.u1, gain.y)
        switch.y ~ FRT_characteristic_selection.u1,          # connect(switch.y, FRT_characteristic_selection.u1)
        zero_FRT_support.y ~ switch.u3,                      # connect(zero_FRT_support.y, switch.u3)
        switch1.y ~ FRT_characteristic_selection.u3,         # connect(switch1.y, FRT_characteristic_selection.u3)
        switch1.u3 ~ zero_FRT_support.y,                     # connect(switch1.u3, zero_FRT_support.y)
        switch1.u2 ~ picdro.trip,                            # connect(switch1.u2, picdro.trip)
        sLDWindV.diq ~ switch1.u1,                           # connect(sLDWindV.diq, switch1.u1)
        sLDWindV.duac ~ duac,                                # connect(sLDWindV.duac, duac)
    ]
    System(eqs, t, vars, pars; name, systems)
end
