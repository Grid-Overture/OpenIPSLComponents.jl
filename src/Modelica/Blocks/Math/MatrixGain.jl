# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Blocks/Math.mo, block MatrixGain
# Ports are plain variables (u[1:nin], y[1:nout] (MIMO), nin = size(K, 2), nout = size(K, 1)). The gain matrix `K` is
# a numeric coefficient matrix taken before any symbolic block (F-22, point 1), as the table of `CombiTable1Ds`:
# `y = K*u` is written row by row. Omitted: graphical annotations.

@component function MatrixGain(; name, K = [1 0; 0 1])
    K = float.(Array(K))
    nout, nin = size(K)
    vars = @variables begin
        (u(t))[1:nin], [description = "Connector of Real input signals"]
        (y(t))[1:nout], [description = "Connector of Real output signals"]
    end
    System(Equation[y[i] ~ sum(K[i, j] * u[j] for j in 1:nin) for i in 1:nout], t, [u, y], []; name)
end
