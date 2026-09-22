# OpenIPSLComponents.jl

A faithful port of [OpenIPSL 3.1.0](https://github.com/OpenIPSL/OpenIPSL) to
Julia and [ModelingToolkit](https://github.com/SciML/ModelingToolkit.jl) 11:
one Julia file per Modelica class at the same path, the same names for models,
parameters, variables and sub-blocks, the equations in the order of the `.mo`,
quirks included. Pure ModelingToolkit — no dependency on any platform, IR or
framework.

**v1.2.0 — the port is complete.** All **320 classes in scope** (22 265 of
OpenIPSL's 22 910 Modelica source lines), 56 Modelica Standard Library blocks,
**147 Tests** checked against sampled OpenModelica 1.25 trajectories that ship
with the package, and 17 whole systems compared on a 1 ms grid — from the 9-bus
tutorial case to the 1 595-unknown Nordic 44. `Pkg.test()`: **12 457 passed, 0
failed**. Method, numbers and limits: [`VALIDATION.md`](VALIDATION.md).

```julia
using OpenIPSLComponents, ModelingToolkit, OrdinaryDiffEq

@named sys = Example_3()                 # any ported class is a constructor
prob = ODEProblem(mtkcompile(sys), [], (0.0, 20.0))
sol  = solve(prob, Rodas5P(); abstol = 1e-6, reltol = 1e-6)
```

Every class is a constructor taking the `.mo`'s parameters as keyword arguments,
named by its Modelica leaf name (`GENROU`, `PwLine`). The few leaf-name
collisions carry a package prefix (`PSSE_TwoWindingTransformer`). Partial
classes are constructors too, extended with `@unpack` + `extend`.

## Tests

```julia
using Pkg; Pkg.test("OpenIPSLComponents")
```

Two kinds. `test/test_<Name>.jl` are hand-computed: blocks, functions and test
bases checked against values worked out by hand. `test/Tests/<mirror>.jl` are
OpenIPSL's own `Tests`, transcribed 1:1, each simulated with the `experiment`
options its `.mo` declares and compared variable by variable against the
OpenModelica oracle in `test/oracle/<Test>.jl`. A class that OpenIPSL ships
without a Test got one written for this port (`PortTests`, a mirror of
`OpenIPSL.Tests`); the file's header and the oracle's `origin` field say so.

No Modelica tool is needed to run the suite: the reference trajectories are
checked in.

## Reading the source

Each file opens with the `.mo` it comes from, what was omitted (graphical
annotations, always), and — where Julia forced a decision — why. Those comments
are the difference between a port you can audit and one you have to trust:
where OpenIPSL has a quirk, the header says whether it was replicated on
purpose or worked around, so a reader can tell a faithful oddity from a bug.

Tags of the form `F-##`, `PLAN-##` and `rule N` refer to GridOverture's internal
research log for this port, which is not public. Nothing is hidden behind them:
the reasoning each tag labels is written out in full in the comment itself. They
are kept so that the same text serves both repositories.

## Licence and attribution

This package is **MPL-2.0** ([`LICENSE`](LICENSE)). It is a derivative work of
OpenIPSL 3.1.0 and of the Modelica Standard Library 4.0.0, both BSD-3-Clause —
their copyright notices, conditions and disclaimers are in
[`NOTICE.md`](NOTICE.md), which you should read before redistributing.

**The modelling work is theirs.** The copyright in the models belongs to
Prof. Luigi Vanfretti and AlsetLab (OpenIPSL) and to the Modelica Association
(MSL). What is added here is the translation to ModelingToolkit and its
validation.

This project is **not affiliated with, nor endorsed by**, the OpenIPSL project,
AlsetLab, or the Modelica Association.

## Contributing

Issues and bug reports are welcome here. Development happens in a private
repository and lands here as tagged releases, so a pull request may be
re-implemented upstream and credited to you rather than merged as-is; say so in
the issue if that does not work for you.
