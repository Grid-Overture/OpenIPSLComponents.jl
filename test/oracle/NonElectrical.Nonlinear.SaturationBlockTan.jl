# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Generated from OpenModelica 1.25 + OpenIPSL 3.1.0 (2026-09-21), PortTests.NonElectrical.Nonlinear.SaturationBlockTan (a Test of this port, not OpenIPSL's). Do not edit.
(
    test = "NonElectrical.Nonlinear.SaturationBlockTan",
    origin = "PortTests",
    experiment = (startTime = 0.0, stopTime = 5.0, tolerance = 1.0e-6, intervals = 500, method = "dassl"),
    t = [0.0, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.25, 2.5, 2.75, 3.0, 3.25, 3.5, 3.75, 4.0, 4.25, 4.5, 4.75, 5.0],
    vars = Dict{String, Vector{Float64}}(
        "saturationBlockTan.n1" => [-1.0, -1.0, -1.0, -1.0, 0.0, 0.1136575622460947, 0.154630248984379, 0.1956029357226634, 0.2365756224609476, 0.2775483091992319, 0.3185209959375161, 0.3594936826758004, 0.4004663694140848, 0.441439056152369, 0.4824117428906534, 0.5233844296289376, 0.564357116367222, 0.6053298031055062, 0.6463024898437905, 0.6463024898437905, 0.6463024898437905],
        "saturationBlockTan.p1" => [-0.2, -0.2, -0.2, -0.125, -0.05000000000000002, 0.02499999999999997, 0.09999999999999998, 0.175, 0.2499999999999999, 0.325, 0.4, 0.4749999999999999, 0.55, 0.625, 0.7, 0.7749999999999999, 0.8500000000000001, 0.925, 1.0, 1.0, 1.0],
    ),
)
