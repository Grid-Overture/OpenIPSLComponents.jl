# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Generated from OpenModelica 1.25 + OpenIPSL 3.1.0 (2026-09-21), PortTests.NonElectrical.Functions.ImSE_exp (a Test of this port, not OpenIPSL's). Do not edit.
(
    test = "NonElectrical.Functions.ImSE_exp",
    origin = "PortTests",
    experiment = (startTime = 0.0, stopTime = 5.0, tolerance = 1.0e-6, intervals = 500, method = "dassl"),
    t = [0.0, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.25, 2.5, 2.75, 3.0, 3.25, 3.5, 3.75, 4.0, 4.25, 4.5, 4.75, 5.0],
    vars = Dict{String, Vector{Float64}}(
        "imSE_exp.VE_OUT" => [0.000894661519182962, 0.000894661519182962, 0.000894661519182962, 0.000894661519182962, 0.000894661519182962, 0.004211170448855822, 0.01493051340957973, 0.04353271262369938, 0.11, 0.2491671161594379, 0.5177698374656574, 1.003419474945365, 1.835729423741877, 3.199818375279385, 5.352413494860108, 8.640775685106878, 13.52466797839944, 13.52466797839944, 13.52466797839944, 13.52466797839944, 13.52466797839944],
        "imSE_exp.VE_IN" => [0.5, 0.5, 0.5, 0.5, 0.5, 0.625, 0.75, 0.875, 1.0, 1.125, 1.25, 1.375, 1.5, 1.625, 1.75, 1.875, 2.0, 2.0, 2.0, 2.0, 2.0],
    ),
)
