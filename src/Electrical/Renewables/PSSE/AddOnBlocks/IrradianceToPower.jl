# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Renewables/PSSE/AddOnBlocks/IrradianceToPower.mo (extends nothing)
# The PV array's output power from a solar-irradiance and a cell-temperature time series:
#   Ppv = (Ypv/M_b)*fpv*(SolarRadiation.y[1]/Gtstc)*(1 + ap*(SolarArrayTemperature.y[1] - Tcstc))
# with two `Modelica.Blocks.Sources.CombiTimeTable` (ported in step 1.3).
# The `.mo` defaults both tables to `fill(0.0, 0, 2)`, an empty matrix that MSL's own `assert` rejects: that default
# is not replicated, and `SolarRadiationTable` / `SolarArrayTemperatureTable` are required keyword arguments.
# Its only upstream Test is `Renewable.PSSE.PVPlantSolarIrradiance`, which is **N** (WhiteNoiseInjection +
# Blocks.Noise.GlobalSeed over 86 400 s), so this block and the `Irr2Pow` branch of `PV` are validated by
# `test/test_IrradianceToPower.jl` alone.
# Omitted: graphical annotations.

@component function IrradianceToPower(; name, M_b = 100e6, Ypv = 1000, Tcstc = 25, fpv = 0.9, ap = -0.48,
        Gtstc = 1000, SolarRadiationTable, SolarArrayTemperatureTable)
    M_b, Ypv, Tcstc, fpv, ap, Gtstc = float.((M_b, Ypv, Tcstc, fpv, ap, Gtstc))
    pars = @parameters begin
        M_b = M_b, [description = "Equipment apparent power (VA)"]
        Ypv = Ypv, [description = "Rated capacity of the PV array (W)"]
        Tcstc = Tcstc, [description = "PV cell temperature under standard test conditions (K)"]
        fpv = fpv, [description = "PV derating factor"]
        ap = ap, [description = "Temperature coefficient of power"]
        Gtstc = Gtstc, [description = "Radiant energy fluence rate of PV array"]
    end
    systems = @named begin
        SolarRadiation = CombiTimeTable(; table = SolarRadiationTable)
        SolarArrayTemperature = CombiTimeTable(; table = SolarArrayTemperatureTable)
    end
    vars = @variables begin
        Ppv(t), [description = "PV array output power (pu on M_b)"]
    end
    eqs = Equation[
        Ppv ~ (Ypv / M_b) * fpv * (SolarRadiation.y[1] / Gtstc) *
              (1 + ap * (SolarArrayTemperature.y[1] - Tcstc)),
    ]
    System(eqs, t, vars, pars; name, systems)
end
