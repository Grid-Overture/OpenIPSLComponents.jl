# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Generated from OpenModelica 1.25 + OpenIPSL 3.1.0 (2026-09-21), PortTests.Controls.PSSE.ES.BaseClasses.SelectLogic (a Test of this port, not OpenIPSL's). Do not edit.
(
    test = "Controls.PSSE.ES.BaseClasses.SelectLogic",
    origin = "PortTests",
    experiment = (startTime = 0.0, stopTime = 3.0, tolerance = 1.0e-6, intervals = 500, method = "dassl"),
    t = [0.0, 0.15, 0.3, 0.45, 0.6, 0.75, 0.9, 1.05, 1.2, 1.35, 1.5, 1.65, 1.8, 1.95, 2.1, 2.25, 2.4, 2.55, 2.7, 2.85, 3.0],
    vars = Dict{String, Vector{Float64}}(
        "selectLogic.Vout" => [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 3.0, 3.0, 3.0, 3.0, 3.0, 3.0, 3.0],
        "selectLogic.VOEL" => [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0],
        "selectLogic.VUEL" => [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0],
    ),
)
