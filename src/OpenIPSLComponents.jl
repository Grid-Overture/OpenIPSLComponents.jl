# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 translated to ModelingToolkit.jl, batch by batch (PLAN-00).
# One file per Modelica class, at the same path as in OpenIPSL (src/Electrical/Machines/PSAT/Order4.jl <-> Order4.mo);
# the mini-MSL blocks under src/Modelica/Blocks/. Includes in dependency order.
module OpenIPSLComponents

using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits, SymbolicContinuousCallback, SymbolicDiscreteCallback, ImperativeAffect
using ModelingToolkit: @unpack, ParentScope
using ModelingToolkit: SciMLBase                   # RightRootFind: the events of the discrete-logic blocks (F-73)
using ModelingToolkit.Setfield: @set!       # `extend` drops `tstops`: a component that extends a base re-attaches them (F-21)
using OrdinaryDiffEq: OrdinaryDiffEqCore   # BrownFullBasicInit, the DAE re-initialization after the fault events

# Modelica `der(x)` is written `der(x)` here as well: `D` is the damping parameter of baseMachine.
const der = D_nounits

# Modelica `extends Base(comp(k = 1), redeclare Other comp2(...))`: a transcribed composition passes such component
# modifiers to its base as `mods = (; comp = (; k = 1), comp2 = (; redeclare = Other, ...))`, and the base builds each
# component as `redeclared(mods, :comp, Default)(; modified(mods, :comp, (; defaults...))...)` (PLAN-00, Phase 0).
# A `redeclare` replaces the component with its own modifiers (the base's modifiers do not apply to the new class):
# only the outer-SystemBase keyword arguments S_b/fn of the defaults survive a redeclare.
redeclared(mods, key::Symbol, default) = get(get(mods, key, (;)), :redeclare, default)
function modified(mods, key::Symbol, defaults::NamedTuple)
    m = get(mods, key, (;))
    if haskey(m, :redeclare)
        keep = NamedTuple{filter(k -> k in (:S_b, :fn), keys(defaults))}(defaults)
        return merge(keep, Base.structdiff(m, NamedTuple{(:redeclare,)}))
    end
    merge(defaults, m)
end

# Modelica.Constants (MSL 4.0.0 with OpenModelica's ModelicaServices.Machine: eps = 1e-15, small = 1e-60, inf = 1e60),
# referenced with the same dotted path as in the .mo files.
module Modelica
    module Constants
        const eps = 1e-15
        const small = 1e-60
        const inf = 1e60
    end
end

# mini-MSL (Modelica.Blocks 4.0.0), batch 1
for f in ("Math/Gain", "Math/Add", "Math/Add3", "Math/Product", "Math/Feedback", "Math/Division", "Math/MultiSum", "Math/Min",
          "Math/Max", "Math/Abs",
          "Sources/Constant", "Sources/RealExpression", "Sources/BooleanConstant", "Sources/BooleanExpression", "Sources/Step",
          "Sources/Ramp", "Sources/Sine",
          "Nonlinear/Limiter", "Nonlinear/VariableLimiter", "Nonlinear/DeadZone",
          "Logical/Switch", "Logical/GreaterThreshold", "Logical/GreaterEqualThreshold", "Logical/Or",
          "Continuous/Integrator", "Continuous/LimIntegrator", "Continuous/Derivative", "Continuous/FirstOrder",
          "Continuous/TransferFunction",
          # batch 2
          "Math/PolarToRectangular", "Logical/ZeroCrossing",
          # batch 5
          "Nonlinear/PadeDelay", "Nonlinear/FixedDelay", "Tables/CombiTable1Ds", "Math/RealToBoolean",
          "MathBoolean/And",
          # batch 6
          "Math/MultiProduct",
          # batch 7
          "Math/Tan", "Sources/CombiTimeTable",
          # batch 8: the four Math blocks and the first discrete-logic subset (Nor and Pre are the sub-blocks of RSFlipFlop)
          "Math/Sin", "Math/Cos", "Math/MatrixGain", "Math/Pythagoras",
          "Logical/Not", "Logical/Nor", "Logical/Pre", "Logical/Timer", "Logical/RSFlipFlop",
          # batch 10: the only four blocks no library class instantiates -- they come in with Examples.OpenCPS
          "Logical/Xor", "Logical/And", "Logical/LessEqualThreshold", "Sources/BooleanStep",
          # batch 12: the last two blocks of the mini-MSL (PLAN-00, annex B). `Der` is the analytic derivative
          # (F-89) and comes in with FrequencyCalc; `LessThreshold` is the twin of GreaterThreshold and comes in
          # with Relay3.
          "Continuous/Der", "Logical/LessThreshold")
    include("Modelica/Blocks/$f.jl")
end
# mini-MSL analog subset (Modelica.Electrical.Analog 4.0.0), batch 7: only what VSD.AC2DCandDC2AC needs.
# Pin and OnePort first: every two-pin component extends OnePort, which is built on Pin.
for f in ("Interfaces/Pin", "Interfaces/OnePort",
          "Basic/Ground", "Basic/Resistor", "Basic/Inductor", "Basic/Capacitor",
          "Ideal/IdealOpeningSwitch",
          "Sources/SignalVoltage", "Sources/SignalCurrent")
    include("Modelica/Electrical/Analog/$f.jl")
end
# NonElectrical, batch 1
for f in ("Functions/SE", "Functions/SE_exp", "Functions/div0protect", "Functions/ImSE",
          "Nonlinear/Div0block", "Nonlinear/CeilingBlock", "Nonlinear/FEX", "Nonlinear/Deadband1", "Nonlinear/Deadband2",
          "Logical/HV_GATE", "Logical/LV_GATE", "Logical/NegCurLogic", "Logical/Switch_VOEL", "Logical/Switch_VUEL",
          "Continuous/SimpleLag", "Continuous/SimpleLagLim", "Continuous/SimpleLagLimVar", "Continuous/SimpleLead",
          "Continuous/LeadLag", "Continuous/DerivativeLag", "Continuous/IntegratorLimVar", "Continuous/LeadLagLim",
          "Continuous/PI_No_Windup", "Continuous/PID_No_Windup", "Continuous/RampTrackingFilter",
          # batch 12: the NonElectrical blocks no Test, Example or library class of OpenIPSL 3.1.0 instantiates
          "Functions/ImSE_exp", "Logical/Relay", "Logical/Relay3", "Nonlinear/SaturationBlockTan",
          "Nonlinear/FrequencyCalc", "Continuous/SimpleLagRateLimBlock", "Continuous/SimpleLagRateLimVar")
    include("NonElectrical/$f.jl")
end

include("Interfaces/PwPin.jl")
# batch 2: interfaces and the power-flow base
include("Interfaces/PwPin_p.jl")
include("Interfaces/PwPin_n.jl")
include("Electrical/Essentials/pfComponent.jl")
include("Interfaces/Generator.jl")
include("Electrical/Buses/Bus.jl")
include("Electrical/Buses/InfiniteBus.jl")
include("Electrical/Buses/BusExt.jl")
include("Electrical/Buses/InternalBus.jl")   # batch 12
include("Electrical/Banks/PSSE/Shunt.jl")
include("Electrical/Banks/PwCapacitorBank.jl")
include("Electrical/Banks/PwShunt.jl")                          # batch 12
include("Electrical/Banks/PwCapacitorBankWithModification.jl")  # batch 12
include("Electrical/Sensors/PwCurrent.jl")
include("Electrical/Sensors/PwVoltage.jl")
include("Electrical/Sensors/SoftPMU.jl")   # batch 12: needs NonElectrical.Nonlinear.FrequencyCalc
include("Electrical/Branches/PwLine.jl")
include("Electrical/Branches/PSAT/TwoWindingTransformer.jl")
include("Electrical/Branches/PSAT/ThreeWindingTransformer.jl")
include("Electrical/Branches/PSAT/PhaseShiftingTransformer.jl")
include("Electrical/Branches/PSAT/ULTC_VoltageControl.jl")
include("Electrical/Branches/PSSE/TwoWindingTransformer.jl")
include("Electrical/Sources/VoltageSourceReImInput.jl")
include("Electrical/Sources/CurrentSourceReImInput.jl")
include("Electrical/Sources/SourceBehindImpedance/BaseClasses/baseVoltageSource.jl")
include("Electrical/Sources/SourceBehindImpedance/VoltageSources/VSource.jl")
include("Electrical/Sources/SourceBehindImpedance/VoltageSources/VSourceIO.jl")
include("Electrical/Loads/PSAT/BaseClasses/baseLoad.jl")
include("Electrical/Loads/PSAT/VoltageDependent.jl")
include("Electrical/Loads/PSAT/PQ.jl")
include("Electrical/Loads/PSAT/PQvar.jl")
include("Electrical/Loads/PSAT/ExponentialRecovery.jl")
include("Electrical/Loads/PSAT/FrequencyDependent.jl")
include("Electrical/Loads/PSAT/Mixed.jl")
include("Electrical/Loads/PSAT/ZIP.jl")
include("Electrical/Loads/PSAT/ZIP_Jimma.jl")
include("Electrical/Loads/PSAT/ZIP_ExtInput.jl")   # batch 12
include("Electrical/Loads/PSSE/BaseClasses/baseLoad.jl")
include("Electrical/Loads/PSSE/Load.jl")
include("Electrical/Loads/PSSE/Load_variation.jl")
include("Electrical/Loads/PSSE/Load_ExtInput.jl")   # batch 12
include("Electrical/Loads/PSSE/Load_switch.jl")     # batch 12
include("Electrical/Events/PwFault.jl")
include("Electrical/Events/PwFaultPQ.jl")
include("Electrical/Events/Breaker.jl")
include("Electrical/Machines/PSAT/BaseClasses/baseMachine.jl")
include("Electrical/Machines/PSAT/Order4.jl")
include("Electrical/Machines/PSAT/Order2.jl")
include("Electrical/Machines/PSAT/Order3.jl")
include("Electrical/Machines/PSSE/GENCLS.jl")
# batch 6: PSAT machines and motors
include("Electrical/Machines/PSAT/Order6.jl")
include("Electrical/Machines/PSAT/Order5_Type1.jl")
include("Electrical/Machines/PSAT/Order5_Type2.jl")
include("Electrical/Machines/PSAT/MotorTypeI.jl")
include("Electrical/Machines/PSAT/MotorTypeIII.jl")
include("Electrical/Machines/PSAT/MotorTypeV.jl")
# batch 3: PSSE machines
include("Electrical/Machines/PSSE/BaseClasses/baseMachine.jl")
include("Electrical/Machines/PSSE/GENROU.jl")
include("Electrical/Machines/PSSE/GENROE.jl")
include("Electrical/Machines/PSSE/GENSAL.jl")
include("Electrical/Machines/PSSE/GENSAE.jl")
include("Electrical/Machines/PSSE/GENTPJ.jl")
include("Electrical/Banks/PSSE/CSVGN1.jl")
include("Electrical/Banks/PSSE/SVC.jl")   # batch 12: needs PwShunt, Relay3, LeadLag, SimpleLagLim, PwVoltage
include("Electrical/Controls/PSSE/ES/BaseClasses/SelectLogic.jl")   # batch 12: a base class nothing in OpenIPSL instantiates
include("Electrical/Controls/PSSE/ES/BaseClasses/BaseExciter.jl")
include("Electrical/Controls/PSSE/ES/ConstantExcitation.jl")
# batch 4: PSSE exciters
include("Electrical/Controls/PSSE/ES/BaseClasses/invFEX.jl")
include("Electrical/Controls/PSSE/ES/BaseClasses/calculate_dc_exciter_params.jl")
include("Electrical/Controls/PSSE/ES/BaseClasses/RectifierCommutationVoltageDrop.jl")
include("Electrical/Controls/PSSE/ES/BaseClasses/RotatingExciterBase.jl")
include("Electrical/Controls/PSSE/ES/BaseClasses/RotatingExciter.jl")
include("Electrical/Controls/PSSE/ES/BaseClasses/RotatingExciterLimited.jl")
include("Electrical/Controls/PSSE/ES/BaseClasses/RotatingExciterWithDemagnetization.jl")
include("Electrical/Controls/PSSE/ES/BaseClasses/RotatingExciterWithDemagnetizationLimited.jl")
include("Electrical/Controls/PSSE/ES/BaseClasses/RotatingExciterWithDemagnetizationVarLim.jl")
include("Electrical/Controls/PSSE/ES/SEXS.jl")
include("Electrical/Controls/CGMES/ES/ExcSEXS.jl")
include("Electrical/Controls/PSSE/ES/EXST1.jl")
include("Electrical/Controls/PSSE/ES/EXNI.jl")
include("Electrical/Controls/PSSE/ES/SCRX.jl")
include("Electrical/Controls/PSSE/ES/ESST1A.jl")
include("Electrical/Controls/PSSE/ES/ST5B.jl")
include("Electrical/Controls/PSSE/ES/URST5T.jl")
include("Electrical/Controls/PSSE/ES/IEEET1.jl")
include("Electrical/Controls/PSSE/ES/IEEET2.jl")
include("Electrical/Controls/PSSE/ES/IEEEX1.jl")
include("Electrical/Controls/PSSE/ES/ESDC1A.jl")
include("Electrical/Controls/PSSE/ES/ESDC2A.jl")
include("Electrical/Controls/PSSE/ES/DC4B.jl")
include("Electrical/Controls/PSSE/ES/EXAC1.jl")
include("Electrical/Controls/PSSE/ES/EXAC2.jl")
include("Electrical/Controls/PSSE/ES/ESAC1A.jl")
include("Electrical/Controls/PSSE/ES/EXBAS.jl")
include("Electrical/Controls/PSSE/ES/ESAC2A.jl")
include("Electrical/Controls/PSSE/ES/AC7B.jl")
include("Electrical/Controls/PSSE/ES/AC8B.jl")
include("Electrical/Controls/PSSE/ES/ESURRY.jl")
include("Electrical/Controls/PSSE/ES/ESST4B.jl")
include("Electrical/Controls/PSSE/ES/ESST2A.jl")
include("Electrical/Controls/PSSE/COMP/IEEEVC.jl")
include("Electrical/Controls/PSSE/UEL/MNLEX2.jl")
include("Electrical/Controls/PSSE/TG/BaseClasses/BaseGovernor.jl")
include("Electrical/Controls/PSSE/TG/ConstantPower.jl")
include("Electrical/Controls/PSSE/PSS/BaseClasses/BasePSS.jl")
include("Electrical/Controls/PSSE/PSS/DisabledPSS.jl")
include("Electrical/Machines/PSSE/Plant.jl")
include("Electrical/Machines/PSSE/BaseClasses/baseMotor.jl")
include("Electrical/Machines/PSSE/CIM5.jl")
include("Electrical/Machines/PSSE/CIM6.jl")   # batch 12
include("Electrical/Loads/PSAT/ThermostaticallyControlled.jl")
include("Electrical/Branches/Generic/ULTC.jl")
include("Electrical/Controls/PSAT/AVR/AVRTypeII.jl")
# batch 6: PSAT controls
include("Electrical/Controls/PSAT/AVR/AVRtypeIII.jl")
include("Electrical/Controls/PSAT/AVR/AVRTypeI.jl")
include("Electrical/Controls/PSAT/OEL/FieldCurrent.jl")
include("Electrical/Controls/PSAT/OEL/OEL.jl")
include("Electrical/Controls/PSAT/PSS/PSSTypeII.jl")
include("Electrical/Controls/PSAT/PSS/PSSTypeI.jl")     # batch 12
include("Electrical/Controls/PSAT/PSS/PSSTypeIII.jl")   # batch 12
include("Electrical/Controls/PSAT/TG/TGTypeII.jl")
include("Electrical/Controls/PSAT/TG/TGTypeI.jl")
include("Electrical/Controls/PSAT/TG/TGTypeIII.jl")
include("Electrical/Controls/PSAT/TG/TGTypeIV.jl")
include("Electrical/Controls/PSAT/TG/TGTypeV.jl")
include("Electrical/Controls/PSAT/TG/TGTypeVI.jl")
include("Electrical/FACTS/PSAT/STATCOM.jl")
include("Electrical/FACTS/PSAT/TCSC.jl")
include("Examples/Tutorial/Example_3/Generation_Groups/Gen1.jl")
include("Examples/Tutorial/Example_3/Generation_Groups/Gen2.jl")
include("Examples/Tutorial/Example_3/Generation_Groups/Gen3.jl")
include("Examples/Tutorial/Example_3/Example_3.jl")
# batch 4: the TwoAreas examples
include("Examples/TwoAreas/Support/Generator.jl")
include("Examples/TwoAreas/Data/PF2.jl")
include("Examples/TwoAreas/Groups/PSSE/No_Controls.jl")
include("Examples/TwoAreas/Groups/PSSE/AVR/G1.jl")
include("Examples/TwoAreas/Groups/PSSE/AVR/G2.jl")
include("Examples/TwoAreas/Groups/PSSE/AVR/G3.jl")
include("Examples/TwoAreas/Groups/PSSE/AVR/G4.jl")
include("Examples/TwoAreas/Two_Areas_PSSE.jl")
include("Examples/TwoAreas/Two_Areas_PSSE_AVR.jl")
# batch 5: PSSE governors extending BaseGovernor
include("Electrical/Controls/PSSE/TG/TGOV1.jl")
include("Electrical/Controls/PSSE/TG/IEEEG2.jl")
include("Electrical/Controls/PSSE/TG/IEESGO.jl")
include("Electrical/Controls/PSSE/TG/GAST.jl")
include("Electrical/Controls/PSSE/TG/HYGOV.jl")
include("Electrical/Controls/PSSE/TG/DEGOV.jl")
include("Electrical/Controls/PSSE/TG/IEEEG1.jl")
include("Electrical/Controls/PSSE/TG/WSIEG1.jl")
include("Electrical/Controls/PSSE/TG/WPIDHY.jl")
include("Electrical/Controls/CGMES/TG/GovHydroIEEE0.jl")
include("Electrical/Controls/PSSE/TG/BaseClasses/GGOV1/Flag.jl")
include("Electrical/Controls/PSSE/TG/BaseClasses/GGOV1/Dm_select.jl")
include("Electrical/Controls/PSSE/TG/BaseClasses/GGOV1/R_select.jl")
include("Electrical/Controls/PSSE/TG/BaseClasses/GGOV1/Min_select.jl")
include("Electrical/Controls/PSSE/TG/BaseClasses/GGOV1/AccelerationLimiter.jl")
include("Electrical/Controls/PSSE/TG/BaseClasses/GGOV1/LoadLimiter.jl")
include("Electrical/Controls/PSSE/TG/BaseClasses/GGOV1/LoadLimiterDU.jl")
include("Electrical/Controls/PSSE/TG/BaseClasses/GGOV1/PIDGovernor.jl")
include("Electrical/Controls/PSSE/TG/BaseClasses/GGOV1/PIDGovernorDU.jl")
include("Electrical/Controls/PSSE/TG/BaseClasses/GGOV1/Turbine.jl")
include("Electrical/Controls/PSSE/TG/GGOV1.jl")
include("Electrical/Controls/PSSE/TG/GGOV1DU.jl")
include("Electrical/Controls/PSSE/TG/BaseClasses/WEHGOV/Governor.jl")
include("Electrical/Controls/PSSE/TG/BaseClasses/WEHGOV/Turbine.jl")
include("Electrical/Controls/PSSE/TG/WEHGOV.jl")
include("Electrical/Controls/PSSE/PSS/PSS2A.jl")
include("Electrical/Controls/PSSE/PSS/PSS2B.jl")
include("Electrical/Controls/PSSE/PSS/IEEEST.jl")
include("Electrical/Controls/PSSE/PSS/IEE2ST.jl")   # batch 12
include("Electrical/Controls/PSSE/PSS/STAB3.jl")    # batch 12
include("Electrical/Controls/PSSE/PSS/STABNI.jl")   # batch 12
include("Electrical/Controls/PSSE/PSS/STBSVC.jl")   # batch 12
include("Electrical/Controls/PSSE/OEL/IF_comparisor.jl")   # batch 12
include("Electrical/Controls/PSSE/OEL/OEL.jl")             # batch 12 (PSSE_OEL)
include("Electrical/Controls/PSSE/PSS/STAB2A.jl")
# batch 5: the Example_4 and SevenBus cases
include("Examples/Tutorial/Example_4/PFData/PF00000.jl")
include("Examples/Tutorial/Example_4/BaseModels/GeneratingUnits/InfiniteBus.jl")
include("Examples/Tutorial/Example_4/BaseModels/GeneratingUnits/GeneratorTurbGovAVR.jl")
include("Examples/Tutorial/Example_4/BaseModels/GeneratingUnits/GeneratorTurbGovAVRPSS.jl")
include("Examples/Tutorial/Example_4/BaseModels/BaseNetwork/SMIBPartial.jl")
include("Examples/Tutorial/Example_4/Experiments/SMIB.jl")
include("Examples/Tutorial/Example_4/Experiments/SMIBVarLoad.jl")
include("Examples/SevenBus/Data.jl")
include("Examples/SevenBus/Generators/G1.jl")
include("Examples/SevenBus/Generators/G2.jl")
include("Examples/SevenBus/Generators/G3.jl")
include("Examples/SevenBus/Network.jl")
# batch 6: the ten PSAT Examples cases
include("Examples/KundurSMIB/SMIB_Partial.jl")
include("Examples/KundurSMIB/Generation_Groups/Generator.jl")
include("Examples/KundurSMIB/Generation_Groups/Generator_AVR.jl")
include("Examples/KundurSMIB/Generation_Groups/Generator_AVR_PSS.jl")
include("Examples/KundurSMIB/SMIB.jl")
include("Examples/KundurSMIB/SMIB_AVR.jl")
include("Examples/KundurSMIB/SMIB_AVR_PSS.jl")
include("Examples/Tutorial/Example_1/Generator/Generator.jl")
include("Examples/Tutorial/Example_1/Example_1.jl")
include("Examples/Tutorial/Example_2/Generator/Generator.jl")
include("Examples/Tutorial/Example_2/Example_2.jl")
include("Examples/TwoAreas/Data/PF1.jl")
include("Examples/TwoAreas/Groups/PSAT/G1.jl")
include("Examples/TwoAreas/Groups/PSAT/G2.jl")
include("Examples/TwoAreas/Groups/PSAT/G3.jl")
include("Examples/TwoAreas/Groups/PSAT/G4.jl")
include("Examples/TwoAreas/Two_Areas_PSAT.jl")
include("Examples/IEEE9/Generation_Groups/Gen1.jl")
include("Examples/IEEE9/Generation_Groups/Gen2.jl")
include("Examples/IEEE9/Generation_Groups/Gen3.jl")
include("Examples/IEEE9/IEEE_9_Buses_Statcom.jl")
include("Examples/IEEE14/Generation_Groups/GroupBus1.jl")
include("Examples/IEEE14/Generation_Groups/GroupBus2.jl")
include("Examples/IEEE14/Generation_Groups/GroupBus3.jl")
include("Examples/IEEE14/Generation_Groups/GroupBus6.jl")
include("Examples/IEEE14/Generation_Groups/GroupBus8.jl")
include("Examples/IEEE14/IEEE_14_Buses.jl")
include("Examples/PSATSystems/TwoArea/BaseClasses/BaseNetwork.jl")
include("Examples/PSATSystems/TwoArea/BaseClasses/BaseOrder4.jl")
include("Examples/PSATSystems/TwoArea/FourthOrder_AVRII.jl")
include("Examples/PSATSystems/ThreeArea/BaseClasses/BaseNetwork.jl")
include("Examples/PSATSystems/ThreeArea/BaseClasses/BaseOrder6.jl")
include("Examples/PSATSystems/ThreeArea/SixthOrder_AVRIII.jl")

# Renewables PSSE (WECC), batch 7
for f in ("InverterInterface/BaseClasses/LVPL", "InverterInterface/BaseClasses/LVACM",
          "InverterInterface/BaseClasses/BaseREGC", "InverterInterface/REGCA1",
          "ElectricalController/BaseClasses/PIwithNoVariableLimiter",
          "ElectricalController/BaseClasses/PIwithVariableLimiter",
          "PlantController/BaseClasses/BaseREPC", "PlantController/REPCA1",
          "ElectricalController/BaseClasses/BaseREECB", "ElectricalController/BaseClasses/CurrentLimitLogicREECB",
          "ElectricalController/REECB1", "PV",
          "ElectricalController/BaseClasses/BaseREECC", "ElectricalController/BaseClasses/CurrentLimitLogicREECC",
          "ElectricalController/BaseClasses/StateOfChargeLogic", "ElectricalController/REECCU1", "BESS",
          "ElectricalController/BaseClasses/BaseREECA", "ElectricalController/BaseClasses/CurrentLimitLogicREECA",
          "ElectricalController/REECA1",
          "WindDriveTrain/BaseClasses/BaseWTDT", "WindDriveTrain/WTDTA1", "Wind",
          "AddOnBlocks/IrradianceToPower")
    include("Electrical/Renewables/PSSE/$f.jl")
end
# Solar and wind, batch 8 (PLAN-08): PSAT solar, PowerFactory General + WECC PVD1 + DIgSILENT, GE Type 3, PSAT Type 3,
# PSSE WT4G. WindGenerator before the two type-3 turbines that read it.
for f in ("Solar/PSAT/ConstantPQPV/PQ1", "Solar/PSAT/ConstantPQPV/PV1",
          "Solar/PowerFactory/General/ElmVac", "Solar/PowerFactory/General/ElmGenstat", "Solar/PowerFactory/General/StaVmea",
          "Solar/PowerFactory/General/Picdro", "Solar/PowerFactory/General/ElmPhi_pll",   # ElmPhi_pll: batch 12
          "Solar/PowerFactory/WECC/PVD1/GenerationTripping", "Solar/PowerFactory/WECC/PVD1/PQPriority",
          "Solar/PowerFactory/WECC/PVD1/Controller", "Solar/PowerFactory/WECC/PVD1/PlantPVD1",
          "Solar/PowerFactory/DIgSILENT/PVModule", "Solar/PowerFactory/DIgSILENT/PVArray", "Solar/PowerFactory/DIgSILENT/DCBusBar",
          "Solar/PowerFactory/DIgSILENT/Auxiliary/SLDWindV", "Solar/PowerFactory/DIgSILENT/Auxiliary/ReactivePowerSupport",
          "Solar/PowerFactory/DIgSILENT/Auxiliary/ActivePowerController", "Solar/PowerFactory/DIgSILENT/CurrentLimiter",
          "Solar/PowerFactory/DIgSILENT/Controller", "Solar/PowerFactory/DIgSILENT/PV_Plant",
          "Wind/WindGenerator",
          "Wind/GE/Type_3/Turbine/Multi_Powers", "Wind/GE/Type_3/Turbine/Cp_function", "Wind/GE/Type_3/Turbine/Wind_Power_Model",
          "Wind/GE/Type_3/Turbine/Rotor_Model", "Wind/GE/Type_3/Turbine/Turbine_Model",
          "Wind/GE/Type_3/Electrical_Control/lim_exc_s1", "Wind/GE/Type_3/Electrical_Control/Electrical_Control",
          "Wind/GE/Type_3/Generator/Generator", "Wind/GE/Type_3/GE_WT",
          "Wind/PSAT/PSAT_Type_3/WindBlk", "Wind/PSAT/PSAT_Type_3/MechaBlk", "Wind/PSAT/PSAT_Type_3/PitchControl",
          "Wind/PSAT/PSAT_Type_3/ElecBlk", "Wind/PSAT/PSAT_Type_3/ElecDynBlk", "Wind/PSAT/PSAT_Type_3/PSAT_WT",
          "Wind/PSSE/Submodels/LVPL", "Wind/PSSE/Submodels/LVACL", "Wind/PSSE/Submodels/HVRCL", "Wind/PSSE/Submodels/CCL",
          "Wind/PSSE/WT4G/WT4G1", "Wind/PSSE/WT4G/WT4E1",
          # batch 12: the PSS/E type-3 pair
          "Wind/PSSE/WT3G/WT3G1", "Wind/PSSE/WT3G/WT3E1")
    include("Electrical/$f.jl")
end
# VSD (variable-speed drive), batch 7
for f in ("ControllerLogic/VoltsHertzController", "PowerElectronics/AC2DCandDC2AC")
    include("Electrical/VSD/Generic/$f.jl")
end
# ThreePhase, batch 9 (PLAN-09): the two partial bases first, then buses, lines, loads and banks; the function
# families before the two transformers that evaluate them in their constructor.
include("Electrical/ThreePhase/ThreePhaseComponent.jl")
include("Electrical/ThreePhase/Branches/BaseClasses/baseLine.jl")
for f in ("Buses/Bus_1Ph", "Buses/Bus_2Ph", "Buses/Bus_3Ph", "Buses/InfiniteBus",
          "Branches/Lines/Line_1Ph", "Branches/Lines/Line_2Ph", "Branches/Lines/Line_3Ph",
          "Loads/WyeLoad_1Ph", "Loads/WyeLoad_3Ph", "Loads/DeltaLoad_2Ph", "Loads/DeltaLoad_3Ph",
          "Banks/CapacitorBank_1Ph", "Banks/CapacitorBank_3Ph")
    include("Electrical/ThreePhase/$f.jl")
end
for f in ("Yg_Yg", "D_D", "Y_Y", "D_Yg", "Yg_D", "D_Y", "Y_D", "Y_Yg", "Yg_Y")
    include("Electrical/ThreePhase/Branches/Transformer/TransfConnection/$f.jl")
end
include("Electrical/ThreePhase/Branches/Transformer/Transformer_3Ph.jl")
for f in ("MonoTriFcn/Inverse", "MonoTriFcn/PositiveFilter", "MonoTriFcn/NegZerFilter",
          "TransformerFcn/Yg_Yg", "TransformerFcn/D_D", "TransformerFcn/Y_Y", "TransformerFcn/D_Yg",
          "TransformerFcn/Yg_D", "TransformerFcn/D_Y", "TransformerFcn/Y_D", "TransformerFcn/Y_Yg",
          "TransformerFcn/Yg_Y", "TransformerFcn/Yg_Yg_FinImp", "TransformerFcn/D_D_FinImp",
          "TransformerFcn/Y_Y_FinImp", "TransformerFcn/Y_Yg_FinImp", "TransformerFcn/Yg_Y_FinImp")
    include("Electrical/ThreePhase/Branches/MonoTri/$f.jl")
end
include("Electrical/ThreePhase/Branches/MonoTri/Transformer_MT.jl")
# ThreePhase, batch 13 (PLAN-13): the classes nothing in OpenIPSL 3.1.0 instantiates - the eight dynamic/static
# loads, the measurement bus, and the two LineFcn functions before the hybrid line that evaluates them in its
# constructor.
for f in ("Loads/Dyn_wye_1Ph", "Loads/Dyn_wye_2Ph_balanced", "Loads/Dyn_wye_2Ph_unbalanced",
          "Loads/Dyn_wye_3Ph_balanced", "Loads/Dyn_wye_3Ph_unbalanced", "Loads/WyeDynLoad_3Ph",
          "Loads/DeltaDynLoad_3Ph", "Loads/WyeLoad_2Ph", "Buses/MeasurementBus",
          "Branches/MonoTri/LineFcn/MT_InfiniteImpedances", "Branches/MonoTri/LineFcn/MT_FiniteImpedance")
    include("Electrical/ThreePhase/$f.jl")
end
include("Electrical/ThreePhase/Branches/MonoTri/Line_MT.jl")
# Examples of batch 7: the three microgrid cases
include("Examples/Microgrids/IEEEMicrogrid/Data/PF_results.jl")
include("Examples/Microgrids/IEEEMicrogrid/GeneratorGroups/DieselGeneratorUnit.jl")
include("Examples/Microgrids/IEEEMicrogrid/IEEEMicrogrid.jl")
include("Examples/Microgrids/UniversityCampus/CampusA/PfData/Pf00000.jl")
include("Examples/Microgrids/UniversityCampus/CampusA/GenerationGroups/DynParamRecords.jl")
for f in ("CTG1MachineComplete", "CTG2MachineComplete", "STG1MachineComplete", "STG2MachineComplete")
    include("Examples/Microgrids/UniversityCampus/CampusA/GenerationGroups/$f.jl")
end
include("Examples/Microgrids/UniversityCampus/CampusA/CampusGridA.jl")
include("Examples/Microgrids/UniversityCampus/CampusB/PfData/Pf00000.jl")
include("Examples/Microgrids/UniversityCampus/CampusB/GeneratorGroups/DynParamRecords.jl")
include("Examples/Microgrids/UniversityCampus/CampusB/GeneratorGroups/GasTurbineUnit.jl")
include("Examples/Microgrids/UniversityCampus/CampusB/GeneratorGroups/SteamTurbineUnit.jl")
include("Examples/Microgrids/UniversityCampus/CampusB/CampusGridB.jl")
# Examples of batch 10: the Nordic 44 base case and the OpenCPS resynchronization bench
include("Examples/N44/Base_Case/Data/PF_results.jl")
for f in ("Gen1_bus_3000", "Gen1_bus_7000", "Gen2_bus_3245", "Gen2_bus_3249", "Gen2_bus_5600", "Gen3_bus_3115",
          "Gen3_bus_5300", "Gen3_bus_6100", "Gen3_bus_6700", "Gen3_bus_7100", "Gen4_bus_3300", "Gen4_bus_3359",
          "Gen4_bus_8500", "Gen5_bus_5100", "Gen5_bus_5400", "Gen5_bus_5500", "Gen5_bus_6000", "Gen5_bus_6500")
    include("Examples/N44/Base_Case/Generators/$f.jl")
end
include("Examples/N44/Base_Case/Nordic44_Base_Case.jl")
include("Examples/OpenCPS/Breakers/Breaker.jl")
for f in ("LimitCheck", "FREQ_CALC", "VOLT_CTRL", "ANGLE_CTRL", "FREQ_CTRL", "ACT_UNIT", "RESYNCH_UNIT")
    include("Examples/OpenCPS/Controls/$f.jl")
end
include("Examples/OpenCPS/Generators/G1.jl")
include("Examples/OpenCPS/Generators/G2.jl")
include("Examples/OpenCPS/Network.jl")

export PwPin, Bus, PwLine, TwoWindingTransformer, VoltageDependent, PwFault
export baseLoad, PQ, PQvar
export Order4, AVRTypeII, Gen1, Gen2, Gen3, Example_3
export redeclared, modified
export PwPin_p, PwPin_n, pfComponent, Generator, InfiniteBus, BusExt, Shunt, PwCapacitorBank, PwCurrent, PwVoltage
export PwFaultPQ, Breaker
export baseMachine, Order2, Order3, Order6, Order5_Type1, Order5_Type2
export MotorTypeI, MotorTypeIII, MotorTypeV
export AVRtypeIII, AVRTypeI, FieldCurrent, OEL, PSSTypeII
export TGTypeII, TGTypeI, TGTypeIII, TGTypeIV, TGTypeV, TGTypeVI
export STATCOM, TCSC
export KundurSMIB_Partial, KundurSMIB_Generator, KundurSMIB_Generator_AVR, KundurSMIB_Generator_AVR_PSS
export KundurSMIB_SMIB, KundurSMIB_SMIB_AVR, KundurSMIB_SMIB_AVR_PSS
export Example_1_Generator, Example_1, Example_2_Generator, Example_2
export TwoAreas_PF1, TwoAreas_PSAT_G1, TwoAreas_PSAT_G2, TwoAreas_PSAT_G3, TwoAreas_PSAT_G4, Two_Areas_PSAT
export IEEE9_Gen1, IEEE9_Gen2, IEEE9_Gen3, IEEE_9_Buses_Statcom
export GroupBus1, GroupBus2, GroupBus3, GroupBus6, GroupBus8, IEEE_14_Buses
export TwoArea_BaseNetwork, TwoArea_BaseOrder4, TwoArea_FourthOrder_AVRII
export ThreeArea_BaseNetwork, ThreeArea_BaseOrder6, ThreeArea_SixthOrder_AVRIII
export PSSE_baseLoad, Load, Load_variation
export GENCLS
export PSSE_baseMachine, GENROU, GENROE, GENSAL, GENSAE, GENTPJ, CSVGN1, Plant
export BaseExciter, ConstantExcitation, BaseGovernor, ConstantPower, BasePSS, DisabledPSS
export baseMotor, CIM5, CIM6
export invFEX, calculate_dc_exciter_params, RectifierCommutationVoltageDrop
export RotatingExciterBase, RotatingExciter, RotatingExciterLimited, RotatingExciterWithDemagnetization
export RotatingExciterWithDemagnetizationLimited, RotatingExciterWithDemagnetizationVarLim
export SEXS, ExcSEXS, EXST1, EXNI, SCRX, ESST1A, ST5B, URST5T
export IEEET1, IEEET2, IEEEX1, ESDC1A, ESDC2A, DC4B, EXAC1, EXAC2, ESAC1A, EXBAS, ESAC2A, AC7B, AC8B
export ESURRY, ESST4B, ESST2A, IEEEVC, MNLEX2
export TwoAreas_Generator, TwoAreas_PF2, TwoAreas_NoControls_G1, TwoAreas_NoControls_G2, TwoAreas_NoControls_G3
export TwoAreas_NoControls_G4, TwoAreas_AVR_G1, TwoAreas_AVR_G2, TwoAreas_AVR_G3, TwoAreas_AVR_G4
export Two_Areas_PSSE, Two_Areas_PSSE_AVR
export TGOV1, IEEEG2, IEESGO, GAST, HYGOV, DEGOV, IEEEG1, WSIEG1, WPIDHY, GovHydroIEEE0
export Flag, GGOV1_Flag, Dm_select, R_select, Min_select, AccelerationLimiter, LoadLimiter, LoadLimiterDU
export PIDGovernor, PIDGovernorDU, GGOV1_Turbine, GGOV1, GGOV1DU
export Governor, WEHGOV_Turbine, WEHGOV
export PSS2A, PSS2B, IEEEST, STAB2A
export PSSTypeI, PSSTypeIII, IEE2ST, STAB3, STABNI, STBSVC   # batch 12
export IF_comparisor, PSSE_OEL   # batch 12: `OEL` is already the PSAT one (rule 6.5)
export PwShunt, PwCapacitorBankWithModification, SVC   # batch 12
export ZIP_ExtInput, Load_ExtInput, Load_switch, InternalBus, ElmPhi_pll, SoftPMU   # batch 12
export Example_4_PF00000, Example_4_InfiniteBus, Example_4_GeneratorTurbGovAVR
export Example_4_GeneratorTurbGovAVRPSS, Example_4_SMIBPartial, Example_4_SMIB, Example_4_SMIBVarLoad
export SevenBus_PF_results, SevenBus_G1, SevenBus_G2, SevenBus_G3, SevenBus_Network
export ExponentialRecovery, FrequencyDependent, Mixed, ZIP, ZIP_Jimma, ThermostaticallyControlled
export ThreeWindingTransformer, PhaseShifter, PhaseShiftingTransformer, ULTC_VoltageControl
export ULTC, PSSE_TwoWindingTransformer
export VoltageSourceReImInput, CurrentSourceReImInput, baseVoltageSource, VSource, VSourceIO
export Gain, Add, Add3, Product, Feedback, Division, MultiSum, MultiProduct, Min, Max, Abs, Tan
export Sin, Cos, MatrixGain, Pythagoras
export Not, Nor, Pre_, Timer_, RSFlipFlop   # Pre_/Timer_: `Pre` is exported by ModelingToolkit, `Timer` is a Base type (rule 6.5)
export Xor, Logical_And, LessEqualThreshold, BooleanStep   # Logical_And: `And` is MathBoolean.And (rule 6.5)
export PQ1, PV1, ElmVac, ElmGenstat, StaVmea, Picdro
export GenerationTripping, PQPriority, PVD1_Controller, PlantPVD1
export PVModule, PVArray, DCBusBar, SLDWindV, ReactivePowerSupport, ActivePowerController, CurrentLimiter
export DIgSILENT_Controller, PV_Plant
export WindGenerator, Multi_Powers, Cp_function, Wind_Power_Model, Rotor_Model, Turbine_Model
export lim_exc_s1, Electrical_Control, GE_Generator, GE_WT
export WindBlk, MechaBlk, PitchControl, ElecBlk, ElecDynBlk, PSAT_WT
export Wind_LVPL, LVACL, HVRCL, CCL, WT4G1, WT4E1
export WT3G1, WT3E1, WT3E1_Speed, WT3E1_pf_Controller, WT3E1_ActivePowerControl, WT3E1_ReactivePowerControl   # batch 12
export WT4E1_ActivePowerController, WT4E1_pf_Controller, WT4E1_windControlEmulator
export Constant, RealExpression, BooleanConstant, BooleanExpression, Step, Ramp, Sine
export Limiter, VariableLimiter, DeadZone, Switch, GreaterThreshold, GreaterEqualThreshold, Or
export Integrator, LimIntegrator, Derivative, FirstOrder, TransferFunction
export Der, LessThreshold   # batch 12: the last two mini-MSL blocks (PLAN-00, annex B)
export PolarToRectangular, ZeroCrossing
export FixedDelay, PadeDelay, CombiTable1Ds, CombiTimeTable, RealToBoolean, And
export Pin, OnePort, Ground, Resistor, Inductor, Capacitor, IdealOpeningSwitch, SignalVoltage, SignalCurrent
export LVPL, LVACM, BaseREGC, REGCA1
export PIwithNoVariableLimiter, PIwithVariableLimiter, BaseREPC, REPCA1
export BaseREECB, CurrentLimitLogicREECB, REECB1, PV
export BaseREECC, CurrentLimitLogicREECC, StateOfChargeLogic, REECCU1, BESS
export BaseREECA, CurrentLimitLogicREECA, REECA1
export BaseWTDT, WTDTA1, Wind, IrradianceToPower
export VoltsHertzController, AC2DCandDC2AC
export IEEEMicrogrid_PF_results, DieselGeneratorUnit, IEEEMicrogrid
export CampusA_Pf00000, CampusA_CTG1, CampusA_CTG2, CampusA_STG1, CampusA_STG2
export CTG1MachineComplete, CTG2MachineComplete, STG1MachineComplete, STG2MachineComplete, CampusGridA
export CampusB_Pf00000, CampusB_GT, CampusB_ST, GasTurbineUnit, SteamTurbineUnit, CampusGridB
export N44_PF_results, Nordic44_Base_Case
export Gen1_bus_3000, Gen1_bus_7000, Gen2_bus_3245, Gen2_bus_3249, Gen2_bus_5600, Gen3_bus_3115, Gen3_bus_5300
export Gen3_bus_6100, Gen3_bus_6700, Gen3_bus_7100, Gen4_bus_3300, Gen4_bus_3359, Gen4_bus_8500, Gen5_bus_5100
export Gen5_bus_5400, Gen5_bus_5500, Gen5_bus_6000, Gen5_bus_6500
export OpenCPS_Breaker, LimitCheck, FREQ_CALC, VOLT_CTRL, ANGLE_CTRL, FREQ_CTRL, ACT_UNIT, RESYNCH_UNIT
export OpenCPS_G1, OpenCPS_G2, OpenCPS_Network
export SE, SE_exp, div0protect, ImSE, Div0block, CeilingBlock, FEX, Deadband1, Deadband2
export HV_GATE, LV_GATE, NegCurLogic, Switch_VOEL, Switch_VUEL
export SimpleLag, SimpleLagLim, SimpleLagLimVar, SimpleLead, LeadLag, DerivativeLag, IntegratorLimVar, LeadLagLim
export PI_No_Windup, PID_No_Windup, RampTrackingFilter
# batch 12: the NonElectrical blocks and the ES base class no class of OpenIPSL 3.1.0 instantiates
export ImSE_exp, Relay, Relay3, SaturationBlockTan, FrequencyCalc, SimpleLagRateLimBlock, SimpleLagRateLimVar
export SelectLogic
# ThreePhase, batch 9
export ThreePhaseComponent, baseLine, LINE_ZERO
export Bus_1Ph, Bus_2Ph, Bus_3Ph, ThreePhase_InfiniteBus
export Line_1Ph, Line_2Ph, Line_3Ph
export WyeLoad_1Ph, WyeLoad_3Ph, DeltaLoad_2Ph, DeltaLoad_3Ph
export CapacitorBank_1Ph, CapacitorBank_3Ph
export TransfConnection_Yg_Yg, TransfConnection_D_D, TransfConnection_Y_Y, TransfConnection_D_Yg
export TransfConnection_Yg_D, TransfConnection_D_Y, TransfConnection_Y_D, TransfConnection_Y_Yg, TransfConnection_Yg_Y
export Transformer_3Ph
export Inverse, PositiveFilter, NegZerFilter
export TransformerFcn_Yg_Yg, TransformerFcn_D_D, TransformerFcn_Y_Y, TransformerFcn_D_Yg, TransformerFcn_Yg_D
export TransformerFcn_D_Y, TransformerFcn_Y_D, TransformerFcn_Y_Yg, TransformerFcn_Yg_Y
export TransformerFcn_Yg_Yg_FinImp, TransformerFcn_D_D_FinImp, TransformerFcn_Y_Y_FinImp
export TransformerFcn_Y_Yg_FinImp, TransformerFcn_Yg_Y_FinImp
export Transformer_MT
# ThreePhase, batch 13
export Dyn_wye_1Ph, Dyn_wye_2Ph_balanced, Dyn_wye_2Ph_unbalanced, Dyn_wye_3Ph_balanced, Dyn_wye_3Ph_unbalanced
export WyeDynLoad_3Ph, DeltaDynLoad_3Ph, WyeLoad_2Ph
export MeasurementBus
export MT_InfiniteImpedances, MT_FiniteImpedance, Line_MT

end
