# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/TwoAreas/Data/PF2.mo (record; extends Support/PF_TwoAreas.mo, the partial template)
# The power-flow record is a NamedTuple with the template's three sub-records (voltages, machines, loads); the two
# TwoAreas systems take it as their `PF_results` keyword and read `PF_results.voltages.V1` exactly as the .mo does.
# PF_TwoAreas, the partial record, is this NamedTuple's shape and has no file (PLAN-04). Values as in the .mo
# (W, var, pu, rad). Omitted: `import Modelica.Constants.pi` (unused).

const TwoAreas_PF2 = (;
    voltages = (;
        V1 = 1.03, A1 = 0.35378975855,
        V2 = 1.01, A2 = 0.18336917813,
        V3 = 1.03, A3 = -0.11868238913,
        V4 = 1.01, A4 = -0.29656809182,
        V5 = 1.0069, A5 = 0.24064774259,
        V6 = 0.97914, A6 = 0.06483200039,
        V7 = 0.9610106, A7 = -0.08179502992,
        V8 = 0.94828, A8 = -0.32311454975,
        V9 = 0.9713628, A9 = -0.56119369128,
        V10 = 0.98486, A10 = -0.41387167085,
        V11 = 1.0088, A11 = -0.23424936555),
    machines = (;
        P1_1 = 700000000.0, Q1_1 = 185029600.0,
        P2_1 = 700000000.0, Q2_1 = 234611300.0,
        P3_1 = 719094100.0, Q3_1 = 176026200.0,
        P4_1 = 700000000.0, Q4_1 = 202082700.0),
    loads = (;
        PL7_1 = 967000000.0, QL7_1 = -84700000.0,
        PL9_1 = 1767000000.0, QL9_1 = -230200000.0),
)
