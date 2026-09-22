# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Machines/PSAT/InductiveMotorV_SIMBOpenline_Test.mo, transcribed automatically (2026-09-16); reviewed by hand.
# extends: none (motor - two parallel lines - InfiniteBus, fn = 60, B = 0). The instance is called `motorTypeI` in
# the .mo although the model is MotorTypeV (sic). Omitted: graphical annotations, displayPF.
# The oracle is the braking-region root the motor's `start` values without `/S_b` take OpenModelica to
# (s = 3.76, P = 0.46, Q = 3.68, v = 0.82 pu; F-53). pwLine2 opens from 2 to 3 s.
@component function InductiveMotorV_SIMBOpenline_Test(; name, S_b = 100e6, fn = 60)
    systems = @named begin
        motorTypeI = MotorTypeV(; Sup = 0, angle_0 = -0.02173, P_0 = 251061.717038311, Q_0 = 226568.616630697,
            v_0 = 1.0336, S_b, fn)
        pwLine1 = PwLine(; G = 0.0, B = 0.0, R = 0.01, X = 0.1, S_b, fn)
        pwLine2 = PwLine(; G = 0.0, B = 0.0, R = 0.01, X = 0.1, t1 = 2.0, t2 = 3.0, opening = 1, S_b, fn)
        infiniteBus = InfiniteBus(; angle_0 = 0.0, v_0 = 1.05, S_b, fn)
    end
    eqs = Equation[
        connect(pwLine1.n, infiniteBus.p),
        connect(pwLine2.n, infiniteBus.p),
        connect(pwLine2.p, motorTypeI.p),
        connect(pwLine1.p, motorTypeI.p),
    ]
    System(eqs, t, [], []; name, systems)
end

@testset "Tests.Machines.PSAT.InductiveMotorV_SIMBOpenline_Test" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle",
        "Machines.PSAT.InductiveMotorV_SIMBOpenline_Test.jl"))
    validate_against_oracle(InductiveMotorV_SIMBOpenline_Test, oracle)
end
