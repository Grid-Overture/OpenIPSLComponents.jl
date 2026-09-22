# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/TG/BaseClasses/GGOV1/AccelerationLimiter.mo (model)
# Blocks: acceleration = Gain(Ka*DELT), add = Add, s8 = Derivative(k = 1, T = Ta, y_start = 0, InitialOutput),
# add1 = Add(k2 = -1). Ports as plain variables: SPEED, ASET, FSR (inputs), FSRA (output).
# `s80(fixed = false)` has the `initial equation s80 = 0` and is referenced nowhere else: a dead parameter, kept.
# `DELT` ("time step used in simulation") is replicated as a plain gain factor, not interpreted.
# Omitted: graphical annotations.

@component function AccelerationLimiter(; name, Ka = 10, Ta = 0.1, DELT = 0.005)
    Ka, Ta, DELT = float.((Ka, Ta, DELT))
    n = (; Ka, Ta, DELT)
    pars = @parameters begin
        Ka = Ka, [description = "Acceleration limiter gain"]
        Ta = Ta, [description = "Acceleration limiter time constant"]
        DELT = DELT, [description = "Time step used in simulation"]
        s80 = 0.0
    end
    systems = @named begin
        acceleration = Gain(; k = n.Ka * n.DELT)
        add = Add()
        s8 = Derivative(; k = 1, T = n.Ta, y_start = 0, initType = :InitialOutput)
        add1 = Add(; k2 = -1)
    end
    vars = @variables begin
        SPEED(t), [description = "Machine speed deviation from nominal (pu)"]
        ASET(t), [description = "Acceleration limiter setpoint (p.u./s)"]
        FSRA(t), [description = "Acceleration Controller Output"]
        FSR(t)
    end
    eqs = Equation[
        acceleration.y ~ add.u1,    # connect(acceleration.y, add.u1)
        s8.y ~ add1.u2,             # connect(s8.y, add1.u2)
        acceleration.u ~ add1.y,    # connect(acceleration.u, add1.y)
        add1.u1 ~ ASET,             # connect(add1.u1, ASET)
        s8.u ~ SPEED,               # connect(s8.u, SPEED)
        add.u2 ~ FSR,               # connect(add.u2, FSR)
        add.y ~ FSRA,               # connect(add.y, FSRA)
    ]
    System(eqs, t, vars, pars; name, systems)
end
