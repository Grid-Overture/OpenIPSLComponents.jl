# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/Microgrids/IEEEMicrogrid/Data/ (the records `VoltagesMicrogrid`, `MachinesMicrogrid`,
# `LoadsMicrogrid` and the collection `PF_results`).
# The three sub-records and their collection are one NamedTuple, as `SevenBus_PF_results` is: `IEEEMicrogrid.jl`
# reads `pf.voltages.V1`, `pf.machines.PDT`, `pf.loads.P1` exactly as the .mo does. Named `IEEEMicrogrid_PF_results`
# (JULIA_NAMES).
# Angles are given in the .mo as `<deg>*C.pi/180` and are written here already in radians, to the same digits.
# `PInf` and `QInf` are in the record and **the system does not read them**: its `GRID = GENCLS` keeps the
# `pfComponent` defaults (sic). Kept, because the record has them.

const IEEEMicrogrid_PF_results = (;
    voltages = (;
        V1 = 1.00000, A1 = 0.0 * pi / 180,                      # HVBus
        V2 = 1.00, A2 = 0.001322568 * pi / 180,                 # LVBus
        V3 = 1.00, A3 = 0.001845621 * pi / 180,                 # SubBus
        V4 = 1.00, A4 = 0.002433209 * pi / 180,                 # CentralBus
        V5 = 1.00, A5 = 0.002433209 * pi / 180,                 # LoadBus
        V6 = 1.00, A6 = 0.003302665 * pi / 180,                 # CapBus
        V7 = 1.00, A7 = 0.002433209 * pi / 180),                # Motor
    machines = (;
        PDT = 0.02e6, QDT = -0.0313e6,                          # diesel unit
        PPV = 0.035e6, QPV = 0.0115e6,                          # PV
        PBESS = 0.0055e6, QBESS = 0.0,                          # BESS
        PInf = -0.0405e6, QInf = 0.0121e6),                     # the grid (not read by the system, sic)
    loads = (;
        P1 = 0.02e6, Q1 = 0.0123e6),
)
