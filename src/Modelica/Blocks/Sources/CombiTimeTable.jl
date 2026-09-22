# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Blocks/Sources.mo, block CombiTimeTable
# Ports are plain variables (y[1:nout] from MO, nout = max(length(columns), length(offset))). Same shape as
# CombiTable1Ds.jl, with the abscissa being time instead of an input: the external table object is replaced by the
# interpolation written symbolically, `smoothness = LinearSegments` (the only one ported) as one chain of `ifelse`
# over `(time - shiftTime)/timeScale`, with no `when` and no event.
# MSL generates time events at the table's abscissas (`timeEvents = Always`) so that the solver lands on each break
# point. Here there is none: with `LinearSegments` and distinct abscissas the value is continuous across a break and
# only the derivative jumps, which the adaptive solver resolves; MSL's own events exist for `ConstantSegments` and
# for repeated abscissas, neither of which is ported. A user that needs the break points exactly passes them as
# `tstops` (F-14's last line).
# `extrapolation`: `:LastTwoPoints` (the MSL default, the line through the first/last two points) and
# `:HoldLastPoint` (the first/last value held), which REECCU1's VDL tables need. Below `startTime` the output is
# `offset` (MSL: "Output = offset for time < startTime"); with the default `startTime = 0` that branch is inert and
# is not written.
# The default `table = fill(0.0, 0, 2)` is not replicated: MSL rejects it with an `assert`, so `table` is a required
# keyword argument here.
# Omitted: `tableOnFile`/`tableName`/`fileName`/`verboseRead` (no user reads a file), `verboseExtrapolation` and its
# two warning asserts, the `ConstantSegments`/Akima/Steffen smoothness branches, the `Periodic`/`NoExtrapolation`
# extrapolations, `timeEvents`, `t_min`/`t_max`, graphical annotations.

@component function CombiTimeTable(; name, table, columns = nothing, smoothness = :LinearSegments,
        extrapolation = :LastTwoPoints, timeScale = 1, offset = [0], startTime = 0, shiftTime = nothing)
    table = float.(Array(table))
    columns = columns === nothing ? collect(2:size(table, 2)) : collect(columns)
    smoothness == :LinearSegments || error("CombiTimeTable: only smoothness = :LinearSegments is ported (got $smoothness)")
    extrapolation in (:LastTwoPoints, :HoldLastPoint) ||
        error("CombiTimeTable: only extrapolation = :LastTwoPoints or :HoldLastPoint is ported (got $extrapolation)")
    offset = float.(collect(offset))
    timeScale, startTime = float(timeScale), float(startTime)
    shiftTime = shiftTime === nothing ? startTime : float(shiftTime)
    nout = max(length(columns), length(offset))
    p_offset = length(offset) == 1 ? fill(offset[1], nout) : offset
    x = table[:, 1]
    n = length(x)
    vars = @variables begin
        (y(t))[1:nout], [description = "Connector of Real output signals"]
    end
    # the scaled abscissa MSL interpolates on
    u = (t - shiftTime) / timeScale
    # linear interpolation of column `c`, the segments folded from the last one backwards (CombiTable1Ds.jl)
    function interp(c)
        v = table[:, c]
        n == 1 && return v[1] + 0 * u
        uc = extrapolation == :HoldLastPoint ? max(x[1], min(u, x[n])) : u
        expr = v[n - 1] + (uc - x[n - 1]) * (v[n] - v[n - 1]) / (x[n] - x[n - 1])
        for i in (n - 2):-1:1
            expr = ifelse(uc < x[i + 1], v[i] + (uc - x[i]) * (v[i + 1] - v[i]) / (x[i + 1] - x[i]), expr)
        end
        expr
    end
    System(Equation[y[i] ~ p_offset[i] + interp(columns[i]) for i in 1:nout], t, [y], []; name)
end
