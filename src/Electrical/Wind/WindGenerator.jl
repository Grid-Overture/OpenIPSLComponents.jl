# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Wind/WindGenerator.mo (extends nothing)
# Blocks: none. Port is a plain variable (Vw). `typ` is an Integer parameter chosen in Julia (F-50): 1 = constant
# `Vw = v0`; 2 = gust, `if time > tstart and time < tstop then v0 + wmag*(1 - cos((time - tstart)*2*pi/wgwidth))/2
# else v0`, continuous with a derivative jump at the two edges -> an `ifelse` on `t` with `tstops = [[tstart, tstop]]`
# (F-14, F-25: no value jump, so no discrete event is needed); 3 = Mexican hat, smooth, `Modelica.Constants.e^x`
# is `exp(x)`. `wgwidth = tstop - tstart` is the protected parameter. Omitted: the `import`s, graphical annotations.

@component function WindGenerator(; name, tstart = 5, tstop = 10, v0 = 14, vmax = 25, wmag = -4, sigma = 1, typ = 1)
    tstart, tstop, v0, vmax, wmag, sigma = float.((tstart, tstop, v0, vmax, wmag, sigma))
    typ in (1, 2, 3) || error("WindGenerator: typ must be 1 (constant), 2 (gust) or 3 (Mexican hat), got $typ")
    wgwidth = tstop - tstart
    tstartn, tstopn = tstart, tstop
    pars = @parameters begin
        tstart = tstart, [description = "Start time of the wind gust (s)"]
        tstop = tstop, [description = "Stop time of the wind gust (s)"]
        v0 = v0, [description = "steady state wind speed (m/s)"]
        vmax = vmax, [description = "peak wind speed for Mexican Hat (m/s)"]
        wmag = wmag, [description = "magnitude of the gust of wind (m/s)"]
        sigma = sigma, [description = "Mexican hat wavelet shape factor"]
        wgwidth = wgwidth, [description = "tstop - tstart (s)"]
    end
    vars = @variables begin
        Vw(t), [description = "Connector of Real output signal (m/s)"]
    end
    eq = typ == 1 ? (Vw ~ v0) :
         typ == 2 ? (Vw ~ ifelse((t > tstart) & (t < tstop), v0 + wmag * (1 - cos((t - tstart) * 2 * pi / wgwidth)) / 2, v0)) :
         (Vw ~ v0 + (vmax - v0) * (1 - (t - (tstop + tstart) / 2)^2 / sigma^2) * exp(-(t - (tstop + tstart) / 2)^2 / (2 * sigma^2)))
    kw = typ == 2 ? (; tstops = [[tstartn, tstopn]]) : (;)
    System(Equation[eq], t, vars, pars; name, kw...)
end
