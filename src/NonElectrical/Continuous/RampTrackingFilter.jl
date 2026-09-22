# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - NonElectrical/Continuous/RampTrackingFilter.mo (model)
# Blocks: TF1[M] = TransferFunction(b = {1}, a = {T_2, 1}, y_start) and TF2[N] = TransferFunction(b = {T_1, 1},
# a = {T_2, 1}, y_start), conditional on `bypass = M == 0 or N == 0`. ModelingToolkit has no arrays of systems: the
# copies are the subsystems TF2_1 … TF2_N, TF1_1 … TF1_M (OM names TF2[1].y …, mapped with `rename` in a Test).
# The four non-bypass branches of the .mo build the same chain u -> TF2[1..N] -> TF1[1..M] -> y (the
# `M == 1 and N == 1` branch is unreachable after the `M == 1` one). Ports are plain variables (u, y).
# Omitted: graphical annotations.

@component function RampTrackingFilter(; name, T_1, T_2, M = 5, N = 1, y_start = 0)
    T_1, T_2, y_start = float.((T_1, T_2, y_start))
    a1, b2, ys = [T_2, 1.0], [T_1, 1.0], y_start   # numeric coefficients, before @parameters rebinds the names
    pars = @parameters begin
        T_1 = T_1
        T_2 = T_2
        y_start = y_start, [description = "Output start value"]
    end
    vars = @variables begin
        u(t), [description = "Connector of Real input signal"]
        y(t), [description = "Connector of Real output signal"]
    end
    bypass = M == 0 || N == 0
    bypass && return System(Equation[u ~ y], t, vars, pars; name)
    TF1 = [TransferFunction(; name = Symbol("TF1_", i), b = [1.0], a = a1, y_start = ys) for i in 1:M]
    TF2 = [TransferFunction(; name = Symbol("TF2_", i), b = b2, a = a1, y_start = ys) for i in 1:N]
    chain = [TF2; TF1]
    eqs = Equation[chain[1].u ~ u; [chain[i + 1].u ~ chain[i].y for i in 1:length(chain) - 1]; y ~ chain[end].y]
    System(eqs, t, vars, pars; name, systems = chain)
end
