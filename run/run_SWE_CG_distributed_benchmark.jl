

using GridapSWE

# command to execute:
# mpiexecjl -n 4 julia --project=. run/run_SWE_CG_distributed_benchmark.jl

dom_params = Dict(
        :Lx => 1.0,              # Domain x-axis length
        :Ly => 1.0,              # Domain y-axis length
        :Nx => 20,               # Domain x-axis number of cells
        :Ny => 20)               # Domain y-axis number of cells 
        
# Solver parameters
solver_params = Dict(
        :Δt => 0.001,             # Time step size
        :t0 => 0.0,               # Initial time
        :tF => 0.01,              # Final time
        :tableau => :SDIRK_3_3,   # Butcher tableau for the time-stepping scheme (e.g., SDIRK_3_3 for a 3-stage, 3rd-order SDIRK method)
        :ls_atol => 1e-8,         # Absolute tolerance for the linear solver
        :ls_rtol => 1e-6,         # Relative tolerance for the linear
        :ls_maxiter => 1000,      # Maximum number of iterations for the linear solver
        :nls_atol => 1e-6,        # Absolute tolerance for the
        :nls_rtol => 1e-4,        # Relative tolerance for the nonlinear solver
        :nls_maxiter => 1000,     # Maximum number of iterations for the nonlinear solver
        :Δit => 10)               # Print info every Δit time steps

GridapSWE.run_distributed_benchmark(:CG, dom_params, solver_params, (2,2), output=true)