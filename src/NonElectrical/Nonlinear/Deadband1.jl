# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - NonElectrical/Nonlinear/Deadband1.mo (model)
# Ports are plain variables (u, y; SISO). `err < eps` is a parameter test, decided at construction.
# Omitted: graphical annotations.

@component function Deadband1(; name, db = 0.1, err = 0.1)
    step = err < Modelica.Constants.eps ? db : err   # on the numeric kwargs, before @parameters rebinds them
    pars = @parameters begin
        db = db, [description = "Deadband"]
        err = err, [description = "Step"]
    end
    vars = @variables begin
        u(t), [description = "Connector of Real input signal"]
        y(t), [description = "Connector of Real output signal"]
    end
    System(Equation[y ~ ifelse(u >= db, u - step, ifelse(u <= -db, u + step, 0))], t, vars, pars; name)
end
