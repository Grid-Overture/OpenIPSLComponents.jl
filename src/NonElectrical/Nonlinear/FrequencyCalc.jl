# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - NonElectrical/Nonlinear/FrequencyCalc.mo (model): frequency deviation from a rotating phasor,
# y = (Vr*der(Vi) - Vi*der(Vr)) / (Vr^2 + Vi^2), in rad/s.
# Blocks: derOfReal, derOfImag = Modelica.Blocks.Continuous.Der; ImagXderReal, RealXderImag, imag2, real2 =
# Modelica.Blocks.Math.Product; diff = Add(k2 = -1); sum = Add; division = Modelica.Blocks.Math.Division.
# Ports are plain variables (real_part, imag_part, y). Omitted: graphical annotations.

# `Ts`, `start_guess`, `real_start` and `imag_start` are declared by the .mo and reach nothing: the two derivative
# blocks are bare `Der`, whose whole body is `y = der(u)`, with no state, no time constant and no `initType`, and
# the protected `init_type` the .mo computes from `start_guess` is never used. The four are kept as parameters
# (rule 5) and are dead here as they are there (F-89). The documented "filtered derivative" is an exact one.
# The consequence is the index: where `real_part` is an algebraic unknown of a network (`Sensors.SoftPMU`), the
# two `Der` equations raise the index of the system and `mtkcompile` reduces it - which OpenModelica 1.25 cannot
# do on the SMIB (F-89, probe of PLAN-12 step 2.1).
# `sum` is renamed `sum_`: `sum` is a Base function (rule 6.5).
@component function FrequencyCalc(; name, start_guess = false, real_start = 1, imag_start = 0, Ts = 0.01)
    real_start, imag_start, Ts = float.((real_start, imag_start, Ts))
    pars = @parameters begin
        start_guess = start_guess
        real_start = real_start, [description = "Phasor initial real part"]
        imag_start = imag_start, [description = "Phasor initial imaginary part"]
        Ts = Ts, [description = "Smoothing filter time constant (s)"]
    end
    systems = @named begin
        derOfReal = Der()
        derOfImag = Der()
        ImagXderReal = Product()
        RealXderImag = Product()
        imag2 = Product()
        real2 = Product()
        diff = Add(; k2 = -1)
        sum_ = Add()
        division = Division()
    end
    vars = @variables begin
        real_part(t)
        imag_part(t)
        y(t), [description = "O/P is in rad/sec"]
    end
    eqs = Equation[
        division.u1 ~ diff.y,   # connect(diff.y, division.u1)
        division.u2 ~ sum_.y,   # connect(sum.y, division.u2)
        y ~ division.y,   # connect(division.y, y)
        sum_.u1 ~ real2.y,   # connect(real2.y, sum.u1)
        sum_.u2 ~ imag2.y,   # connect(imag2.y, sum.u2)
        derOfReal.u ~ real_part,   # connect(real_part, derOfReal.u)
        imag2.u1 ~ imag_part,   # connect(imag2.u1, imag_part)
        imag2.u2 ~ imag_part,   # connect(imag2.u2, imag_part)
        RealXderImag.u2 ~ derOfImag.y,   # connect(derOfImag.y, RealXderImag.u2)
        derOfImag.u ~ imag_part,   # connect(derOfImag.u, imag_part)
        RealXderImag.u1 ~ real_part,   # connect(real_part, RealXderImag.u1)
        diff.u1 ~ RealXderImag.y,   # connect(RealXderImag.y, diff.u1)
        diff.u2 ~ ImagXderReal.y,   # connect(ImagXderReal.y, diff.u2)
        ImagXderReal.u1 ~ imag_part,   # connect(ImagXderReal.u1, imag_part)
        ImagXderReal.u2 ~ derOfReal.y,   # connect(derOfReal.y, ImagXderReal.u2)
        real2.u2 ~ real_part,   # connect(real2.u2, real_part)
        real2.u1 ~ real_part,   # connect(real2.u1, real_part)
    ]
    System(eqs, t, vars, pars; name, systems)
end
