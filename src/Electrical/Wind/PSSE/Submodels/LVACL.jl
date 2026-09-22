# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Wind/PSSE/Submodels/LVACL.mo (extends nothing)
# Blocks: none. Ports are plain variables (Vt, Ip_LVPL; Ip_LVACL). The thresholds 0.4 and 0.8 are hard-coded in the
# .mo; the characteristic is continuous at 0.8 (Ip*1.25*0.8 = Ip) and **discontinuous at 0.4** (0.5*Ip -> 0), sic,
# although the comment of the .mo says "linear ... to zero". An `ifelse` without event. Omitted: the comments of the
# .mo, graphical annotations.

@component function LVACL(; name)
    vars = @variables begin
        Ip_LVACL(t), [description = "Active current after the low-voltage limiter"]
        Vt(t), [description = "Terminal voltage (pu)"]
        Ip_LVPL(t), [description = "Active current before the low-voltage limiter"]
    end
    System(Equation[Ip_LVACL ~ ifelse(Vt < 0.4, 0, ifelse(Vt > 0.8, Ip_LVPL, Ip_LVPL * 1.25 * Vt))], t, vars, []; name)
end
