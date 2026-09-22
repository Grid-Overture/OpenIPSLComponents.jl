# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Generated from OpenModelica 1.25 + OpenIPSL 3.1.0 (2026-09-13), Tests.NonElectrical.Nonlinear.Div0Block. Do not edit.
(
    test = "NonElectrical.Nonlinear.Div0Block",
    experiment = (startTime = 0.0, stopTime = 1.0, tolerance = 1.0e-6, intervals = 500),
    t = [0.0, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 1.0],
    vars = Dict{String, Vector{Float64}}(
        "div0block1.y" => [1.0e60, 1.0e60, 1.0e60, 1.0e60, 1.0e60, 1.0e60, 1.0e60, 1.0e60, 1.0e60, 1.0e60, 1.0e60, 1.0e60, 1.0e60, 1.0e60, 1.0e60, 1.0e60, 1.0e60, 1.0e60, 1.0e60, 1.0e60, 1.0e60],
        "div0block1.u1" => [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0],
        "div0block1.u2" => [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    ),
)
