# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/OpenCPS/Generators/G2.mo (extends Electrical/Essentials/pfComponent.mo)
# 24 kV / 100 MVA unit of bus B5 of the OpenCPS bench, the one that is resynchronized: GENSAL + SEXS + IEESGO
# plus the `central_Unit = RESYNCH_UNIT`, which drives the unit through the governor's power reference
# (`P_CTRL -> iEESGO.PMECH0`) and the exciter's stabilizer input (`V_CTRL -> sEXS.VOTHSG`) and exports the
# breaker's gating signal `TRIGGER`. `non_active_limits(k = 0)` goes to the SEXS's VOEL and VUEL follows VOEL.
# The four measurements `V_IB`, `V_DN`, `fi_IB`, `fi_DN` and the flag `TRIGGER` are the .mo's RealInput /
# BooleanOutput ports, plain variables here. The pin is `conn`.
# Named `OpenCPS_G2` (JULIA_NAMES). Omitted: graphical annotations, displayPF.

@component function OpenCPS_G2(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0)
    @named base = pfComponent(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    systems = @named begin
        conn = PwPin()
        gen = GENSAL(; M_b = 100e6, Tpd0 = 5, Tppd0 = 0.07, Tppq0 = 0.09, H = 4.28, D = 0, Xd = 1.84, Xq = 1.75,
            Xpd = 0.41, Xppd = 0.2, Xl = 0.12, S10 = 0.11, S12 = 0.39, Xppq = 0.2, R_a = 0,
            V_b, v_0, angle_0, P_0, Q_0, S_b, fn)
        sEXS = SEXS(; T_AT_B = 0.2, K = 50, E_MIN = 0, E_MAX = 5, T_E = 0.01, T_B = 10)
        non_active_limits = Constant(; k = 0)
        iEESGO = IEESGO(; P_MAX = 1.5, P_MIN = 0)
        central_Unit = RESYNCH_UNIT()
    end
    vars = @variables begin
        V_IB(t), [description = "Connector of Real input signal"]
        V_DN(t), [description = "Connector of Real input signal"]
        fi_IB(t), [description = "Connector of Real input signal"]
        fi_DN(t), [description = "Connector of Real input signal"]
        TRIGGER(t), [description = "Connector of Boolean output signal (0/1)"]
    end
    eqs = Equation[
        connect(gen.p, conn),
        gen.EFD ~ sEXS.EFD,                     # connect(sEXS.EFD, gen.EFD)
        sEXS.ECOMP ~ gen.ETERM,                 # connect(sEXS.ECOMP, gen.ETERM)
        sEXS.EFD0 ~ gen.EFD0,                   # connect(gen.EFD0, sEXS.EFD0)
        sEXS.VOEL ~ non_active_limits.y,        # connect(non_active_limits.y, sEXS.VOEL)
        sEXS.VUEL ~ sEXS.VOEL,                  # connect(sEXS.VUEL, sEXS.VOEL)
        central_Unit.V_IB ~ V_IB,               # connect(V_IB, central_Unit.V_IB)
        gen.PMECH ~ iEESGO.PMECH,               # connect(iEESGO.PMECH, gen.PMECH)
        iEESGO.SPEED ~ gen.SPEED,               # connect(iEESGO.SPEED, gen.SPEED)
        central_Unit.PMECH0 ~ gen.PMECH0,       # connect(central_Unit.PMECH0, gen.PMECH0)
        central_Unit.V_DN ~ V_DN,               # connect(V_DN, central_Unit.V_DN)
        central_Unit.fi_DN ~ fi_DN,             # connect(fi_DN, central_Unit.fi_DN)
        central_Unit.fi_IB ~ fi_IB,             # connect(fi_IB, central_Unit.fi_IB)
        central_Unit.SPEED ~ gen.SPEED,         # connect(central_Unit.SPEED, gen.SPEED)
        TRIGGER ~ central_Unit.TRIGGER,         # connect(TRIGGER, central_Unit.TRIGGER)
        iEESGO.PMECH0 ~ central_Unit.P_CTRL,    # connect(central_Unit.P_CTRL, iEESGO.PMECH0)
        sEXS.VOTHSG ~ central_Unit.V_CTRL,      # connect(central_Unit.V_CTRL, sEXS.VOTHSG)
        sEXS.XADIFD ~ gen.XADIFD,               # connect(gen.XADIFD, sEXS.XADIFD)
    ]
    extend(System(eqs, t, vars, []; name, systems), base)
end
