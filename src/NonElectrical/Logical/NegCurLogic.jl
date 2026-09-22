# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - NonElectrical/Logical/NegCurLogic.mo (model)
# Ports are plain variables (Vd, XadIfd, Efd) with start = nstartvalue as guesses. `abs(RC_rfd) < eps` is a parameter
# test, decided at construction. Omitted: graphical annotations.

@component function NegCurLogic(; name, RC_rfd, nstartvalue)
    crowbar_off = abs(RC_rfd) < Modelica.Constants.eps   # on the numeric kwarg, before @parameters rebinds it
    pars = @parameters begin
        RC_rfd = RC_rfd
        nstartvalue = nstartvalue
    end
    vars = @variables begin
        Vd(t), [guess = nstartvalue]
        Efd(t), [guess = nstartvalue]
        XadIfd(t), [guess = nstartvalue]
        Crowbar_V(t)
    end
    eqs = Equation[
        Efd ~ ifelse(XadIfd < 0, Crowbar_V, Vd),
        Crowbar_V ~ (crowbar_off ? 0 : (-1) * RC_rfd * XadIfd),
    ]
    System(eqs, t, vars, pars; name)
end
