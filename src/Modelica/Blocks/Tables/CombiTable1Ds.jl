# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Blocks/Tables.mo, block CombiTable1Ds
# Ports are plain variables (u; y[1:nout] from SIMO, nout = length(columns)). The external table object of MSL is
# replaced by the interpolation itself, written symbolically: `smoothness = LinearSegments` and
# `extrapolation = LastTwoPoints` (both MSL 4.0.0 defaults) are one chain of `ifelse` over the abscissa, with no
# `when` and no event. The chain is exactly MSL's semantics: the branch
# `u < table[2, 1]` carries the first segment, which extrapolated below `table[1, 1]` is the line through the first
# two points, and the final `else` carries the last segment, which above `table[end, 1]` is the line through the last
# two points.
# `extrapolation = :HoldLastPoint` (batch 7: the VDL tables of `REECCU1`) is the same chain with the abscissa
# clamped to `[x[1], x[end]]` beforehand, two extra `ifelse` through `max`/`min`: inside the range nothing changes,
# outside it the first/last table value is held, which is MSL's definition.
# The table points of OpenIPSL's users are model parameters (`GV1..GV5`/`PGV1..PGV5` of `WSIEG1`, `G0..G2`/`P1..P3`
# of `WPIDHY`, `FLWG*`/`FLWP*` of `WEHGOV.Turbine`), so the matrix is assembled from the numeric keyword arguments
# before `@parameters` (F-22, point 1).
# Omitted: `tableOnFile`/`tableName`/`fileName`/`verboseRead` (no user reads a file), `verboseExtrapolation` and its
# asserts, the `ConstantSegments`/Akima/Steffen smoothness branches and the other extrapolations, `u_min`/`u_max`,
# graphical annotations.

@component function CombiTable1Ds(; name, table, columns = [2], smoothness = :LinearSegments,
        extrapolation = :LastTwoPoints)
    table = float.(Array(table))
    smoothness == :LinearSegments || error("CombiTable1Ds: only smoothness = :LinearSegments is ported (got $smoothness)")
    extrapolation in (:LastTwoPoints, :HoldLastPoint) ||
        error("CombiTable1Ds: only extrapolation = :LastTwoPoints or :HoldLastPoint is ported (got $extrapolation)")
    nout = length(columns)
    x = table[:, 1]
    n = length(x)
    vars = @variables begin
        u(t), [description = "Connector of Real input signal"]
        (y(t))[1:nout], [description = "Connector of Real output signals"]
    end
    # linear interpolation of column `c` at `u`, the segments folded from the last one backwards
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
    System(Equation[y[i] ~ interp(columns[i]) for i in 1:nout], t, [u, y], []; name)
end
