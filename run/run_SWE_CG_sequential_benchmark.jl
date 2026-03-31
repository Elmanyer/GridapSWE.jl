

using GridapSWE

# command to execute:
# julia --project=. run/run_SWE_CG_sequential_benchmark.jl

dom_params = Dict(
        :Lx => 1.0,              # Domain x-axis length
        :Ly => 1.0,              # Domain y-axis length
        :Nx => 20,               # Domain x-axis number of cells
        :Ny => 20)               # Domain y-axis number of cells 
        
# Solver parameters
solver_params = Dict(
        :dt => 0.001,             # Time step size
        :t0 => 0.0,               # Initial time
        :tF => 0.01,              # Final time
        :tableau => :SDIRK_3_3,   # Butcher tableau for the time-stepping scheme (e.g., SDIRK_3_3 for a 3-stage, 3rd-order SDIRK method)
        :Δit => 10)               # Print info every Δit time steps

GridapSWE.run_sequential_benchmark(:sinusoidal, :CG, dom_params, solver_params, output=true)