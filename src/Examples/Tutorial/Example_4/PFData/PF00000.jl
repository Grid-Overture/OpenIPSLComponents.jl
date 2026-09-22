# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/Tutorial/Example_4/PFData/PF00000.mo and the four records it redeclares
# (BusData/PFBus00000.mo, LoadData/PFLoad00000.mo, MachineData/PFMachine00000.mo, TrafoData/PFTrafo00000.mo).
# The `PowerFlow` -> `PowerFlowTemplate` -> {Bus, Load, Machine, Trafo}Template hierarchy of `replaceable record`s is
# flattened to one NamedTuple: what the .mo reads as `pf.powerflow.bus.v1` is `pf.bus.v1` here (there is one
# power-flow record per case and nothing redeclares its parts other than PF00000 itself). `Trafo` is empty, as in
# `TrafoTemplate`. Values as in the .mo (pu, rad, W, var).

const Example_4_PF00000 = (;
    bus = (; v1 = 1.0, A1 = 0.0706208, v2 = 1.0, A2 = 0.0, v3 = 0.9959842, A3 = -0.0050087,
        v4 = 0.9919935, A4 = -0.0100578),
    load = (; PL1 = 1e6 * 50.0, QL1 = 1e6 * 10.0),
    machine = (; PG1 = 1e6 * 40.0, QG1 = 1e6 * 5.416582, PG2 = 1e6 * 10.0171156, QG2 = 1e6 * 8.006544),
    trafo = (;),
)
