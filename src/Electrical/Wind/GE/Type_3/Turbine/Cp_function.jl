# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Wind/GE/Type_3/Turbine/Cp_function.mo (extends Modelica.Blocks.Icons.Block, nothing
# to port)
# Blocks, with the names of the .mo: matrixGain1 = MatrixGain(K) with the 5x5 matrix of GE (the same `coeff` as
# `GE_WT.cp_init`), multi_Powers1 (on Lambda), multi_Powers2 (on Theta). Ports are plain variables (Lambda, Theta;
# y). `cp = theta_vec' * K * lambda_vec`, written as the five products of the .mo. Omitted: graphical annotations.

const GE_CP_COEFF = [-0.41909 0.21808 -0.012406 -0.00013365 0.000011524;
                     -0.067606 0.060405 -0.013934 0.0010683 -0.000023895;
                     0.015727 -0.010996 0.0021495 -0.00014855 0.0000027937;
                     -0.00086018 0.00057051 -0.00010479 0.0000059924 -0.000000089194;
                     0.000014788 -0.0000094839 0.0000016167 -0.000000071535 0.00000000049686]

@component function Cp_function(; name)
    systems = @named begin
        matrixGain1 = MatrixGain(; K = GE_CP_COEFF)
        multi_Powers1 = Multi_Powers()
        multi_Powers2 = Multi_Powers()
    end
    vars = @variables begin
        Lambda(t), [description = "Lambda"]
        Theta(t), [description = "Pitch angle"]
        y(t), [description = "Cp"]
    end
    eqs = Equation[
        Theta ~ multi_Powers2.u1,                    # connect(Theta, multi_Powers2.u1)
        Lambda ~ multi_Powers1.u1,                   # connect(Lambda, multi_Powers1.u1)
        [multi_Powers1.y[i] ~ matrixGain1.u[i] for i in 1:5]...,   # connect(multi_Powers1.y[i], matrixGain1.u[i])
        y ~ matrixGain1.y[1] * multi_Powers2.y[1] + matrixGain1.y[2] * multi_Powers2.y[2] +
            matrixGain1.y[3] * multi_Powers2.y[3] + matrixGain1.y[4] * multi_Powers2.y[4] +
            matrixGain1.y[5] * multi_Powers2.y[5],
    ]
    System(eqs, t, vars, []; name, systems)
end
