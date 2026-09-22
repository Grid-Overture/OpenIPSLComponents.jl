# Validation

Every class in this package was checked against the same class running in
[OpenModelica](https://openmodelica.org) 1.25 with OpenIPSL 3.1.0. This page
states the method and the result. The evidence ships with the package: the
reference trajectories are in `test/oracle/`, so `Pkg.test()` reproduces the
whole check on your machine, offline, with no Modelica tool installed.

## Method

1. The upstream Modelica `Test` is simulated in OpenModelica 1.25 with the
   `experiment` options the `.mo` itself declares — its own solver, stop time
   and tolerance, not ours.
2. Its trajectory is sampled at `t = 0` plus 20 instants spread over the
   interval and stored as `test/oracle/<Test>.jl`, one file per Test, together
   with the options that produced it.
3. The transcribed Julia Test is simulated and compared **variable by
   variable** against that sample. A variable passes when

   ```
   max |MTK − OM|  ≤  1e-4 + 1e-3 · max|OM|
   ```

   The Test passes when every variable passes. Each Test prints its worst
   variable and the ratio of its error to that limit, so a regression shows up
   as a number, not as a red/green flip.
4. A class that OpenIPSL 3.1.0 ships **without** a Test got one written for this
   port, run through the same pipeline; its oracle carries `origin = "PortTests"`.

Where a Test needs something the default path does not give — a different
nonlinear solver for the initialization, a different integrator, a solver
tolerance, a renamed variable — the Test declares it explicitly and prints it on
the same line. Nothing is relaxed silently.

## Result

| | |
| --- | ---: |
| Library classes in scope, ported | **320 of 320** |
| Modelica source lines covered | 22 265 of 22 910 |
| Modelica Standard Library blocks ported | 56 |
| Tests against an OpenModelica oracle, passing | **147** |
| — transcribed from OpenIPSL's own `Tests` | 108 |
| — written for this port (`PortTests`) | 39 |
| `Examples` systems compared against OpenModelica | 17, all passing |
| `Pkg.test()` | **12 457 passed, 0 failed** (68 min, Julia 1.13) |

The 20 classes not ported are out of scope for a stated reason: 13 are
Simulink-inherited ports unused in 3.1.0, 4 are stochastic (no deterministic
reference is possible), 2 are graphics-only, and 1 is the `inner`/`outer`
`SystemBase`, replaced here by the `S_b` and `fn` parameters that every
constructor takes.

Systems compared span the range from the 9-bus tutorial case to the Nordic 44
model, which compiles to 1 595 unknowns. Whole-system comparisons are made on a
1 ms grid rather than at 21 sampled instants.

## Limits, stated plainly

- **Six of OpenIPSL's own Tests are excluded**: OpenModelica 1.25 cannot
  simulate them at all, so no reference trajectory exists to compare against.
  They are `TestBreaker`, `ESURRY`, `PSS.PSS2A`, `PVPlantSolarIrradiance`,
  `Wind.PSAT.WT_Test` and `Wind.PSSE.WT4G.WT4E1`; the failures are upstream, not
  in this port.
- **Four validation systems have no OpenModelica reference** for the same
  reason, and are resolved without one.
- **The oracle is a sample, not a continuous comparison.** 21 instants per Test
  catch a trajectory that drifts; they would not catch a transient that lives
  entirely between two of them. The whole-system cases, on a 1 ms grid, do.
- **The reference is OpenModelica, not measurement.** This port is validated to
  agree with OpenIPSL as OpenModelica 1.25 runs it. Where OpenIPSL itself
  deviates from the model it implements, the port reproduces the deviation on
  purpose — faithfulness to 3.1.0 is the goal, and the file's header comment
  says so wherever a quirk was replicated rather than fixed.

## Reproducing it

```julia
using Pkg; Pkg.test("OpenIPSLComponents")
```

No Modelica installation is needed: the reference trajectories are checked in.
