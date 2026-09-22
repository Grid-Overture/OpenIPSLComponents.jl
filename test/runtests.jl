# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
using Test
using OpenIPSLComponents
using ModelingToolkit, OrdinaryDiffEq
using ModelingToolkit: t_nounits as t, D_nounits, @unpack
using NonlinearSolve: NewtonRaphson, LevenbergMarquardt, FastShortcutNonlinearPolyalg
# FastShortcutNonlinearPolyalg is the default of the ODE path, named here so that a Test can ask for it back
using ModelingToolkit.SciMLBase: OverrideInit
using DelayDiffEq: MethodOfSteps, DDEProblem   # a model with a FixedDelay(delayTime > 0) is a DDE (F-20 d)

# The Tests initialize with an exact Newton iteration from the models' guesses. The default of the ODE path
# (`FastShortcutNonlinearPolyalg`: Broyden/Klement from an identity Jacobian first) walks off to spurious branches of
# the network's algebraic system (Order3test2: bus voltages 2.04 pu with the literal `initial equation der(e1q) = 0`,
# F-26), whereas NewtonRaphson lands on the operating point the guesses describe.
# `nlsolve` of `validate_against_oracle` overrides it where an exact Newton walks off instead (F-30): the SMIB Tests
# with an ideal voltage source at GEN1 have a collapsed-voltage root that Newton reaches from SMIB's own start values.
const INIT = OverrideInit(; nlsolve = NewtonRaphson())

# Test-only ideal voltage source: fixes the pin voltage and absorbs whatever current the component under test imposes.
@component function FixedVoltageSource(; name, vr, vi)
    pars = @parameters begin
        vr = vr
        vi = vi
    end
    systems = @named begin
        p = PwPin()
    end
    System(Equation[p.vr ~ vr, p.vi ~ vi], t, [], pars; name, systems)
end

# Test-only current injection: imposes the current ir + j ii flowing into the pin it is connected to (an unconnected
# pin gets flow ~ 0 from expand_connections, as in Modelica, so a hand test cannot impose a pin current by equation).
@component function CurrentInjection(; name, ir, ii)
    pars = @parameters begin
        ir = ir
        ii = ii
    end
    systems = @named begin
        p = PwPin()
    end
    System(Equation[p.ir ~ -ir, p.ii ~ -ii], t, [], pars; name, systems)
end

# The PSAT TwoWindingTransformer (batch 0) omits the display variables P12/P21/Q12/Q21 and keeps its Complex aliases
# vs, is (pin p) and vr, ir (pin n) as the pin variables: for an oracle that contains such instances (a transformer,
# a three-winding transformer, a phase shifter), the columns to skip and the renames to the pins.
# `pins` names the two pins the aliases belong to: ("s", "r") for Breaker, whose .mo uses the same four alias names
# on pins called s and r (batch 9, Tests.ThreePhase.IEEE13).
function transformer_aliases(oracle; pins = ("p", "n"))
    skip = String[]
    rename = Dict{String, String}()
    for n in keys(oracle.vars)
        occursin(r"\.(P12|P21|Q12|Q21)$", n) && push!(skip, n)
        m = match(r"^(.*)\.(vs|is|vr|ir)\.(re|im)$", n)
        m === nothing && continue
        pin = m[2] in ("vs", "is") ? pins[1] : pins[2]
        rename[n] = m[1] * "." * pin * "." * (m[2] in ("vs", "vr") ? "v" : "i") * (m[3] == "re" ? "r" : "i")
    end
    (; skip, rename)
end

# Row t = 0 of the OpenModelica 1.25 + OpenIPSL 3.1.0 reference (results/raw/om_example3.csv, Phase 1),
# oracle for the machine, AVR and generation-group tests. `state` is AVR.simpleLagLim.state.
const OM_T0 = Dict(
    "gen1" => (delta = 1.066368991341034, e1d = 0.6221979825841122, e1q = 0.7881690180478471,
        state = 1.902077693650219, vf = 1.789323314329605, vref = 1.120103884682511,
        id = 1.290147289022885, iq = 0.9319921848174231),
    "gen2" => (delta = 0.9448622218854307, e1d = 0.6242377620350503, e1q = 0.7678611257780452,
        state = 1.451478672469449, vf = 1.402994304406186, vref = 1.097573933623472,
        id = 0.5614685101026696, iq = 0.6194057884656633),
    "gen3" => (delta = 0.06258547836991349, e1d = 2.969347613498985e-06, e1q = 1.056363824716875,
        state = 1.104854853620832, vf = 1.082148046273887, vref = 1.095242742681042,
        id = 0.3026317084156386, iq = 0.6712424278045058),
)

# Right-hand side of the compiled system at the initialized integrator state: du[i] is the time derivative of
# unknowns(sys)[i]. Initial values are read from `init(prob, ...)` because the DAE initialization (algebraic
# variables, `initialization_eqs`) runs when the integrator is created, not when the problem is built.
function initial_derivative(integ, sys, var)
    du = similar(integ.u)
    integ.f(du, integ.u, integ.p, integ.t)
    i = findfirst(isequal(var), unknowns(sys))
    i === nothing || return du[i]
    # `var` was eliminated as an alias of another unknown (a block whose output is its state: since batch 5 the
    # `SimpleLag` family writes `y = state` instead of an `ifelse`, F-50, so `mtkcompile` may keep either name).
    # Read the observed value along the flow; for an alias the central difference is exact.
    u0, h = copy(integ.u), 1e-7
    integ.u .= u0 .+ h .* du
    a = integ[var]
    integ.u .= u0 .- h .* du
    b = integ[var]
    integ.u .= u0
    (a - b) / (2h)
end

# A Modelica instance whose name is a Julia keyword or a Base constant is suffixed with `_` in the port
# (`const` -> `const_`, `Inf` -> `Inf_`); the same list lives in JULIA_KEYWORDS of the transcriber.
const JULIA_RENAMES = Dict("const" => "const_", "Inf" => "Inf_", "NaN" => "NaN_", "pi" => "pi_", "im" => "im_",
    "abs" => "abs_", "min" => "min_", "module" => "module_",   # batch 8: instances of DIgSILENT (abs, min) and PVArray (module)
    "sum" => "sum_")                                           # batch 12: the Add of FrequencyCalc

# One dotted segment of an OpenModelica variable name to the corresponding ModelingToolkit symbolic. A segment may
# carry array indices ("TF.x[1]"): an array variable is indexed after `getproperty` (F-22, batch 3).
function resolve_path_part(sys, part)
    m = match(r"^([^\[]+)(?:\[([0-9, ]+)\])?$", part)
    v = getproperty(sys, Symbol(get(JULIA_RENAMES, m[1], m[1])))
    m[2] === nothing ? v : v[parse.(Int, split(m[2], ","))...]
end

# An OpenIPSL Test transcribed to test/Tests/<mirror>.jl against its sampled OpenModelica oracle in test/oracle/<Test>.jl
# (PLAN-00, /om-validation section C.3): simulate with the experiment's tolerance, save at the oracle's instants, and
# require max|MTK - OM| <= atol + rtol*max|OM| per oracle variable. `rename` maps an OM variable name to the MTK path
# when the port names a variable differently from the .mo; `skip` drops OM-only columns.
# `u0` is a function of the compiled system returning `var => value` pairs, the initial conditions OpenModelica adds
# when OpenIPSL's Test is under-determined (it fixes start values in declaration order until the initialization is
# square, F-28); the Julia model keeps its literal `start` values as guesses. `nlsolve` replaces the Newton iteration
# of `INIT` for a Test whose network has a second root the exact Newton reaches first (F-30).
#
# `lags` is a function of the compiled system returning the constant delays of a model that contains a
# `FixedDelay(delayTime > 0)`: a non-empty list makes the problem a `DDEProblem` integrated with
# `MethodOfSteps(Rodas5P())` (F-20 d); tstops, saveat and the initialization are the same as on the ODE path.
#
# `tol` replaces the experiment tolerance passed to `solve` for a Test whose quantities of interest are too small
# for it: a purely algebraic network re-solves its equations at every step to `tol`, so a current of 1e-6 pu is
# only as accurate as `tol` itself (`Tests.ThreePhase.IEEE13`, F-82). It is not a threshold: the acceptance stays
# `atol + rtol*max|OM|`.
#
# `alg` replaces `Rodas5P` for a Test whose right-hand side is discontinuous in a *state* at the operating point,
# where a Rosenbrock method's Jacobian is meaningless and its step size collapses: `FBDF()` is the multistep
# family OpenModelica's own DASSL belongs to (F-92).
function validate_against_oracle(ctor, oracle; atol = 1e-4, rtol = 1e-3, rename = Dict{String, String}(),
        skip = String[], tstops = Float64[], u0 = nothing, nlsolve = nothing, lags = nothing, tol = nothing,
        alg = nothing, kwargs...)
    @named model = ctor(; kwargs...)
    sys = mtkcompile(model)
    solvetol = tol
    tol = something(tol, oracle.experiment.tolerance)
    t0 = oracle.experiment.startTime
    constant_lags = lags === nothing ? [] : lags(sys)
    u0vals = u0 === nothing ? [] : u0(sys)
    prob = isempty(constant_lags) ? ODEProblem(sys, u0vals, (t0, oracle.experiment.stopTime)) :
           DDEProblem(sys, u0vals, (t0, oracle.experiment.stopTime); constant_lags)
    # an explicit `tstops` replaces the problem's own (the symbolic tstops of the events, F-21): merge them
    own = get(prob.kwargs, :tstops, Float64[])
    own = own isa AbstractVector ? own : own(prob.p, prob.tspan)   # ModelingToolkit's SymbolicTstops is callable
    all_tstops = sort(unique(Float64[oracle.t; tstops; own]))
    initalg = nlsolve === nothing ? INIT : OverrideInit(; nlsolve)
    base_alg = something(alg, Rodas5P())
    solvealg = isempty(constant_lags) ? base_alg : MethodOfSteps(base_alg)
    sol = solve(prob, solvealg; abstol = tol, reltol = tol, saveat = oracle.t, tstops = all_tstops, initializealg = initalg)
    @test sol.retcode == ReturnCode.Success
    # OM's sample at an event instant is the pre-event row (F-13); an observed variable that depends on a discrete
    # variable evaluates post-event at the saved instant, so MTK is sampled just before it (F-21). This is exact only
    # when every jump of the model is a discrete event with re-initialization (the sources of the mini-MSL, F-25)
    ts = [tk == t0 ? tk : prevfloat(tk) for tk in oracle.t]
    # An event located by root-finding lands a few microseconds apart in the two tools (F-29): when a sampled instant
    # falls inside that window, OM's row is on one side of the event and MTK's sample on the other. Each instant is
    # therefore compared against the closest of the pre-event sample, the value 10 us earlier and the post-event value
    # `sol(tk)` (F-21); away from events the three agree to the interpolation error
    ts_before = [tk == t0 ? tk : tk - 1e-5 for tk in oracle.t]
    worst = (name = "", err = 0.0, limit = Inf)
    for (name, om) in sort(collect(oracle.vars); by = first)
        name in skip && continue
        path = get(rename, name, name)
        var = foldl(resolve_path_part, split(path, "."); init = sys)
        mtk = sol(ts; idxs = var).u
        d = min.(abs.(mtk .- om), abs.(sol(ts_before; idxs = var).u .- om), abs.(sol(oracle.t; idxs = var).u .- om))
        err = maximum(d)
        limit = atol + rtol * maximum(abs.(om))
        err / limit >= worst.err / worst.limit && (worst = (; name, err, limit))
        @test err <= limit
    end
    # The non-default escapes of this call, appended to the line: it is the contract the report generator parses
    # (F-27, F-28, F-29, F-31, F-46, F-49 are the reasons a Test needs one).
    esc = String[]
    atol == 1e-4 || push!(esc, "atol = $atol")
    rtol == 1e-3 || push!(esc, "rtol = $rtol")
    u0 === nothing || push!(esc, "u0")
    nlsolve === nothing || push!(esc, "nlsolve")
    solvetol === nothing || push!(esc, "tol = $solvetol")
    isempty(skip) || push!(esc, "skip = $(length(skip))")
    isempty(rename) || push!(esc, "rename = $(length(rename))")
    lags === nothing || push!(esc, "lags")
    alg === nothing || push!(esc, "alg = $(nameof(typeof(alg)))")
    println("  $(oracle.test): $(length(oracle.vars) - length(skip)) variables, worst $(worst.name) max|Δ| = ",
        round(worst.err; sigdigits = 3), " (limit ", round(worst.limit; sigdigits = 3), ")",
        isempty(esc) ? "" : ", escapes: " * join(esc, ", "))
    sol
end

# A Test whose power-flow point is an UNSTABLE equilibrium (the three batch-7 `Renewable.PSSE` plants with their
# shipped `Kp = 18`, F-64): the trajectory is not reproducible by any solver at any tolerance, because both tools
# amplify their own numerical seed, so only the operating point can be compared. Every oracle variable is checked
# at `t = startTime` against the initialized integrator; the trajectory of those models is validated separately,
# against the `_Kp1` oracle of the same Test, by `validate_against_oracle`.
# The printed line has the same shape as `validate_against_oracle`'s (the contract of the report generator, F-60).
function validate_operating_point(ctor, oracle; atol = 1e-6, rename = Dict{String, String}(), skip = String[],
        nlsolve = nothing, kwargs...)
    @named model = ctor(; kwargs...)
    sys = mtkcompile(model)
    t0 = oracle.experiment.startTime
    prob = ODEProblem(sys, [], (t0, oracle.experiment.stopTime))
    # a tighter Newton than `INIT`'s default: on an unstable point the residual is what the run amplifies
    initalg = OverrideInit(; abstol = 1e-12, reltol = 1e-12,
        nlsolve = nlsolve === nothing ? NewtonRaphson() : nlsolve)
    integ = init(prob, Rodas5P(); initializealg = initalg)
    worst = (name = "", err = 0.0, limit = atol)
    n = 0
    for (name, om) in sort(collect(oracle.vars); by = first)
        name in skip && continue
        path = get(rename, name, name)
        var = foldl(resolve_path_part, split(path, "."); init = sys)
        mtk = try integ[var] catch; integ.ps[var] end
        err = abs(mtk - om[1])
        n += 1
        err >= worst.err && (worst = (; name, err, limit = atol))
        @test err <= atol
    end
    println("  $(oracle.test): $n variables, worst $(worst.name) max|Δ| = ",
        round(worst.err; sigdigits = 3), " (limit ", round(atol; sigdigits = 3), "), escapes: t = 0 only (F-64)")
    integ
end

# Hand tests (test/test_<Name>.jl) and the transcribed OpenIPSL Tests (test/Tests/<mirror>.jl). `Pkg.test()` with no
# argument runs all of them; `Pkg.test(; test_args = ["Order4", "PSAT/"])` runs only the files whose path contains one
# of the arguments (the focused run of a step). The four bases of Tests/BaseClasses/ define functions the Tests call,
# so they are always included.
const HAND_TESTS = [
    "test_Bus.jl",
    "test_PwLine.jl",
    "test_TwoWindingTransformer.jl",
    "test_VoltageDependent.jl",
    "test_PwFault.jl",
    "test_Order4.jl",
    "test_Order5_Type2.jl",
    "test_FieldCurrent.jl",
    "test_PSSTypeII.jl",
    "test_AVRTypeII.jl",
    "test_Gen.jl",
    "test_PQ.jl",
    "test_Modelica_Blocks_Math.jl",
    "test_Modelica_Blocks_Sources.jl",
    "test_Modelica_Blocks_Nonlinear.jl",
    "test_Modelica_Blocks_Logical.jl",
    "test_Modelica_Blocks_Continuous.jl",
    "test_Modelica_Blocks_Tables.jl",
    "test_Modelica_Electrical_Analog.jl",
    "test_REGC_BaseClasses.jl",
    "test_REPC.jl",
    "test_REEC_BaseClasses.jl",
    "test_IrradianceToPower.jl",
    "test_VSD.jl",
    "test_IEEEMicrogrid.jl",
    "test_UniversityCampus.jl",
    "test_NonElectrical_Functions.jl",
    "test_NonElectrical_Nonlinear.jl",
    "test_NonElectrical_Logical.jl",
    "test_NonElectrical_Continuous.jl",
    "test_Interfaces.jl",
    "test_Buses.jl",
    "test_Banks_Sensors.jl",
    "test_Events.jl",
    "test_Load_PSSE.jl",
    "test_PSSE_TwoWindingTransformer.jl",
    "test_CIM5.jl",
    "test_CIM6.jl",   # batch 12
    "test_ES_BaseClasses.jl",
    "test_RotatingExciter.jl",
    "test_ESST2A.jl",
    "test_ESURRY.jl",
    "test_TwoAreas.jl",
    "test_DEGOV.jl",
    "test_GGOV1_BaseClasses.jl",
    "test_PSS2A.jl",
    "test_STAB2A.jl",
    "test_Example_4.jl",
    "test_SevenBus.jl",
    "test_OpenCPS.jl",
    "test_N44.jl",
    "test_KundurSMIB.jl",
    "test_Tutorial_Example_1_2.jl",
    "test_IEEE9_Statcom.jl",
    "test_IEEE14.jl",
    "test_PSATSystems.jl",
    "test_PowerFactory_General.jl",
    "test_PVD1_BaseClasses.jl",
    "test_DIgSILENT_PV.jl",
    "test_WindGenerator.jl",
    "test_GE_Turbine.jl",
    "test_GE_Electrical_Control.jl",
    "test_PSAT_Type_3.jl",
    "test_Wind_PSSE_Submodels.jl",
    "test_WT4E1.jl",
    "test_WT3E1.jl",   # batch 12
    "test_ThreePhase_Buses.jl",
    "test_ThreePhase_Lines.jl",
    "test_ThreePhase_Loads.jl",
    "test_ThreePhase_Banks.jl",
    "test_TransfConnection.jl",
    "test_MonoTriFcn.jl",
    "test_PSSE_OEL.jl",   # batch 12
    "test_TransformerFcn.jl",
    "test_MT_LineFcn.jl",   # batch 13
]

const ORACLE_BASES = [
    "Tests/BaseClasses/MachineTestBase.jl",
    "Tests/BaseClasses/LoadTestBase.jl",
    "Tests/BaseClasses/SMIB.jl",
    "Tests/BaseClasses/TGTestBase.jl",
    "Tests/BaseClasses/SMIBRenewable.jl",
]

const ORACLE_TESTS = [
    "Tests/Machines/PSAT/Order4test2.jl",
    "Tests/Machines/PSAT/Order2test2.jl",
    "Tests/Machines/PSAT/Order2test2_perturbation.jl",
    "Tests/Machines/PSAT/Order3test2.jl",
    "Tests/Machines/PSAT/Order3test2_perturbation.jl",
    "Tests/Machines/PSAT/Order6test2.jl",
    "Tests/Machines/PSAT/Order5test2.jl",
    "Tests/Machines/PSAT/Order4test2_perturbation.jl",
    "Tests/Machines/PSAT/InductiveMotorI_SIMBOpenline_Test.jl",
    "Tests/Machines/PSAT/InductiveMotorIII_SIMBOpenline_Test.jl",
    "Tests/Machines/PSAT/InductiveMotorV_SIMBOpenline_Test.jl",
    "Tests/Machines/PSAT/Order3test2_AVR.jl",
    "Tests/Machines/PSAT/Order4test2_AVR.jl",
    "Tests/Controls/PSAT/AVR/AVRTypeII_Test.jl",
    "Tests/Controls/PSAT/AVR/AVRTypeI_Test.jl",
    "Tests/Controls/PSAT/OEL/AVRTypeII_OEL_Test.jl",
    "Tests/Controls/PSAT/TG/TGTypeII_test.jl",
    "Tests/Machines/PSAT/Order3test2_TG.jl",
    "Tests/Machines/PSAT/Order4test2_TG.jl",
    "Tests/Controls/PSAT/TG/TGTypeI_test.jl",
    "Tests/Controls/PSAT/TG/TGTypeIII_test.jl",
    "Tests/Controls/PSAT/TG/TGTypeIV_test.jl",
    "Tests/Controls/PSAT/TG/TGTypeV_test.jl",
    "Tests/Controls/PSAT/TG/TGTypeVI_test.jl",
    "Tests/FACTS/STATCOM_Test.jl",
    "Tests/FACTS/TCSC_Test.jl",
    "Tests/Loads/PSAT/LoadTestVoltDependant.jl",
    "Tests/Loads/PSAT/LoadTestPQ.jl",
    "Tests/Loads/PSAT/LoadTestExpRecovery.jl",
    "Tests/Loads/PSAT/LoadTestFreqDependent.jl",
    "Tests/Loads/PSAT/LoadTestMixed.jl",
    "Tests/Loads/PSAT/LoadTestZip.jl",
    "Tests/Loads/PSAT/LoadTestZipJimma.jl",
    "Tests/Loads/PSAT/LoadTestThLoad.jl",
    "Tests/Machines/PSSE/GENCLS.jl",
    "Tests/Machines/PSSE/GENROU.jl",
    "Tests/Machines/PSSE/GENROE.jl",
    "Tests/Machines/PSSE/GENSAL.jl",
    "Tests/Machines/PSSE/GENSAE.jl",
    "Tests/Machines/PSSE/GENTPJ.jl",
    "Tests/Branches/PSSE/TwoWindingTransformer.jl",
    "Tests/Banks/PSSE/CSVGN1.jl",
    "Tests/Banks/PwCapacitorBank.jl",   # a Test of this port (PortTests, PLAN-12 phase 0): same path rule, same oracle rule
    "Tests/Machines/PSSE/GEN.jl",
    "Tests/Branches/PSAT/TwoWindingTransformer_Test.jl",
    "Tests/Branches/PSAT/ThreeWindingTransformer_Test.jl",
    "Tests/Branches/PSAT/PhaseShiftingTransformer_Test.jl",
    "Tests/Branches/PSAT/ULTC_Test.jl",
    "Tests/Branches/Generic/ULTC.jl",
    "Tests/Sources/SourcesWithRealInputs/VoltageSourceReImInputConstant.jl",
    "Tests/Sources/SourcesWithRealInputs/VoltageSourceReImInputVaryImag.jl",
    "Tests/Sources/SourcesWithRealInputs/VoltageSourceReImInputVaryReal.jl",
    "Tests/Sources/SourcesWithRealInputs/VoltageSourceReImInputVaryRealAndImag.jl",
    "Tests/Sources/SourcesWithRealInputs/CurrentSourceReImInputConstant.jl",
    "Tests/Sources/SourcesBehindImpedance/VSource.jl",
    "Tests/Sources/SourcesBehindImpedance/VSourceIO.jl",
    "Tests/Sources/SourcesBehindImpedance/VSourceIO_StartFromExternal_using_RealExpression.jl",
    "Tests/Sources/SourcesBehindImpedance/VSourceIO_StartFromExternal_using_VSIO_outputs.jl",
    "Tests/NonElectrical/Nonlinear/Div0Block.jl",
    "Tests/Controls/PSSE/ES/SEXS.jl",
    "Tests/Controls/CGMES/ES/ExcSEXS.jl",
    "Tests/Controls/PSSE/ES/EXST1.jl",
    "Tests/Controls/PSSE/ES/EXNI.jl",
    "Tests/Controls/PSSE/ES/SCRX.jl",
    "Tests/Controls/PSSE/ES/ESST1A.jl",
    "Tests/Controls/PSSE/ES/ST5B.jl",
    "Tests/Controls/PSSE/ES/URST5T.jl",
    "Tests/Controls/PSSE/ES/IEEET1.jl",
    "Tests/Controls/PSSE/ES/IEEET2.jl",
    "Tests/Controls/PSSE/ES/IEEEX1.jl",
    "Tests/Controls/PSSE/ES/ESDC1A.jl",
    "Tests/Controls/PSSE/ES/ESDC2A.jl",
    "Tests/Controls/PSSE/ES/DC4B.jl",
    "Tests/Controls/PSSE/ES/EXAC1.jl",
    "Tests/Controls/PSSE/ES/EXAC2.jl",
    "Tests/Controls/PSSE/ES/ESAC1A.jl",
    "Tests/Controls/PSSE/ES/EXBAS.jl",
    "Tests/Controls/PSSE/ES/ESAC2A.jl",
    "Tests/Controls/PSSE/ES/AC7B.jl",
    "Tests/Controls/PSSE/ES/AC8B.jl",
    "Tests/Controls/PSSE/ES/ESST4B.jl",
    "Tests/Controls/PSSE/COMP/IEEEVC.jl",
    "Tests/Controls/PSSE/UEL/MNLEX2.jl",
    "Tests/Controls/PSSE/TG/TGOV1.jl",
    "Tests/Controls/PSSE/TG/IEEEG2.jl",
    "Tests/Controls/PSSE/TG/IEESGO.jl",
    "Tests/Controls/PSSE/TG/GAST.jl",
    "Tests/Controls/PSSE/TG/HYGOV.jl",
    "Tests/Controls/PSSE/TG/IEEEG1.jl",
    "Tests/Controls/PSSE/TG/WSIEG1.jl",
    "Tests/Controls/PSSE/TG/WPIDHY.jl",
    "Tests/Controls/CGMES/TG/GovHydroIEEE0_Test.jl",
    "Tests/Controls/PSSE/TG/GGOV1DU.jl",
    "Tests/Controls/PSSE/TG/GGOV1.jl",
    "Tests/Controls/PSSE/TG/WEHGOV.jl",
    "Tests/Controls/PSSE/PSS/PSS2B.jl",
    "Tests/Controls/PSSE/PSS/IEEEST.jl",
    "Tests/Renewable/PSSE/PVPlant.jl",
    "Tests/Renewable/PSSE/BESSPlant.jl",
    "Tests/Renewable/PSSE/WindPlant.jl",
    "Tests/Solar/PSAT/SolarPQTest.jl",
    "Tests/Solar/PSAT/SolarPVTest.jl",
    "Tests/Solar/PowerFactory/DIgSILENT_PV.jl",
    "Tests/Solar/PowerFactory/PVD1.jl",
    "Tests/Wind/GE/WT_Test.jl",
    "Tests/Wind/PSSE/WT4G/WT4G1.jl",
    "Tests/ThreePhase/IEEE4.jl",
    "Tests/ThreePhase/IEEE13.jl",
    "Tests/ThreePhase/IEEE4_MonoTri.jl",
    # batch 12 (PLAN-12): this port's own Tests, same path rule and same oracle rule as an upstream one
    "Tests/NonElectrical/Continuous/SimpleLagRateLimBlock.jl",
    "Tests/NonElectrical/Continuous/SimpleLagRateLimVar.jl",
    "Tests/NonElectrical/Functions/ImSE_exp.jl",
    "Tests/NonElectrical/Logical/Relay.jl",
    "Tests/NonElectrical/Logical/Relay3.jl",
    "Tests/NonElectrical/Nonlinear/FrequencyCalc.jl",
    "Tests/NonElectrical/Nonlinear/SaturationBlockTan.jl",
    "Tests/Controls/PSSE/ES/BaseClasses/SelectLogic.jl",
    "Tests/Controls/PSAT/PSS/PSSTypeI.jl",
    "Tests/Controls/PSAT/PSS/PSSTypeIII.jl",
    "Tests/Controls/PSSE/PSS/IEE2ST.jl",
    "Tests/Controls/PSSE/PSS/STAB3.jl",
    "Tests/Controls/PSSE/PSS/STABNI.jl",
    "Tests/Controls/PSSE/PSS/STBSVC.jl",
    "Tests/Controls/PSSE/OEL/OEL.jl",
    "Tests/Banks/PwShunt.jl",
    "Tests/Banks/PwCapacitorBankWithModification.jl",
    "Tests/Banks/PSSE/SVC.jl",
    "Tests/Loads/PSAT/LoadTestZipExtInput.jl",
    "Tests/Loads/PSSE/Load_ExtInput.jl",
    "Tests/Loads/PSSE/Load_switch.jl",
    "Tests/Buses/InternalBus.jl",
    "Tests/Sensors/SoftPMU.jl",
    "Tests/Solar/PowerFactory/General/ElmPhi_pll.jl",
    "Tests/Machines/PSSE/CIM6.jl",
    "Tests/Wind/PSSE/WT3G/WT3G1.jl",
    "Tests/Wind/PSSE/WT3G/WT3E1.jl",
    # batch 13 (PLAN-13): this port's own Tests of the ThreePhase classes nothing in OpenIPSL instantiates
    "Tests/ThreePhase/Dyn_wye_1Ph.jl",
    "Tests/ThreePhase/Dyn_wye_2Ph_balanced.jl",
    "Tests/ThreePhase/Dyn_wye_2Ph_unbalanced.jl",
    "Tests/ThreePhase/Dyn_wye_3Ph_balanced.jl",
    "Tests/ThreePhase/Dyn_wye_3Ph_unbalanced.jl",
    "Tests/ThreePhase/WyeDynLoad_3Ph.jl",
    "Tests/ThreePhase/DeltaDynLoad_3Ph.jl",
    "Tests/ThreePhase/WyeLoad_2Ph.jl",
    "Tests/ThreePhase/MeasurementBus.jl",
    "Tests/ThreePhase/Line_MT.jl",
    "Tests/ThreePhase/Line_MT_FinImp.jl",
]

selected(f) = isempty(ARGS) || any(p -> occursin(p, f), ARGS)

@testset "OpenIPSLComponents" begin
    for f in HAND_TESTS
        selected(f) && include(f)
    end
    @testset "OpenIPSL Tests vs OpenModelica oracles" begin
        foreach(include, ORACLE_BASES)
        for f in ORACLE_TESTS
            selected(f) && include(f)
        end
    end
end
