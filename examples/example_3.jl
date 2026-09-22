# Example_3 — the 9-bus tutorial system of OpenIPSL, simulated for 20 s with a
# three-phase fault at bus 9 between t = 3.0 s and t = 3.1 s.
#
# Run it from this folder:   julia --project=. example_3.jl
# It writes example_3.png next to this file.
#
# The tolerance is 1e-8, not the 1e-6 you might reach for first: the swing of
# this system is undamped over 20 s, and at 1e-6 the integrator has not
# converged — the rotor angles still move by 8.6e-5 rad between the two.

using OpenIPSLComponents, ModelingToolkit, OrdinaryDiffEq, CairoMakie

@named example_3 = Example_3()
sys = mtkcompile(example_3)
prob = ODEProblem(sys, [], (0.0, 20.0))
sol = solve(prob, Rodas5P(); abstol = 1e-8, reltol = 1e-8)

t = range(0, 20, length = 2001)
fig = Figure(size = (900, 600))

# Rotor angles relative to gen1. The absolute angles are what the model
# integrates, but all three drift together with the reference frame, which
# hides the swing; the differences are what a machine's stability is read from.
ax1 = Axis(fig[1, 1]; ylabel = "rotor angle vs gen1 (rad)",
           title = "Example_3 — three-phase fault at bus 9, t ∈ [3.0, 3.1) s")
delta1 = sol(t, idxs = example_3.gen1.gen.delta).u
for (k, g) in ((2, example_3.gen2), (3, example_3.gen3))
    lines!(ax1, t, sol(t, idxs = g.gen.delta).u .- delta1; label = "gen$k − gen1")
end
axislegend(ax1; position = :rt)

ax2 = Axis(fig[2, 1]; xlabel = "time (s)", ylabel = "bus voltage (pu)")
for b in (:B1, :B2, :B3, :B9)
    lines!(ax2, t, sol(t, idxs = getproperty(example_3, b).v).u; label = string(b))
end
axislegend(ax2; position = :rb)

save(joinpath(@__DIR__, "example_3.png"), fig)
println("wrote ", joinpath(@__DIR__, "example_3.png"))
