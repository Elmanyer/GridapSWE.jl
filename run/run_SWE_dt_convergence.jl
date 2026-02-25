
using GridapSWE

# Domain parameters
dom_params = Dict(
        :Lx => 1.0,              # Domain x-axis length
        :Ly => 1.0,              # Domain y-axis length
        :Nx => 10,               # Domain x-axis number of cells
        :Ny => 10)               # Domain y-axis number of cells 

# Solver parameters
solver_params = Dict(
        :Δt => 0.001,             # Time step size
        :t0 => 0.0,               # Initial time
        :tF => 0.1,               # Final time
        :tableau => :SDIRK_3_3,   # Butcher tableau for the time-stepping scheme (e.g., SDIRK_3_3 for a 3-stage, 3rd-order SDIRK method)
        :ls_atol => 1e-10,        # Absolute tolerance for the linear solver
        :ls_rtol => 1e-8,         # Relative tolerance for the linear solver
        :ls_maxiter => 1000,      # Maximum number of iterations for the linear solver
        :nls_atol => 1e-9,        # Absolute tolerance for the nonlinear solver
        :nls_rtol => 1e-7,        # Relative tolerance for the nonlinear solver
        :nls_maxiter => 1000,     # Maximum number of iterations for the nonlinear solver
        :Δit => 10)               # Print info every Δit time steps

for Δt in [0.05, 0.01, 1e-3, 1e-4]
    solver_params[:Δt] = Δt

    # Continuous Galerkin without stabilization
    GridapSWE.run_distributed_benchmark(:CG, dom_params, solver_params, (4,4), output=true)
    # Continuous Galerkin with SUPG stabilization
    GridapSWE.run_distributed_benchmark(:CG_SUPG, dom_params, solver_params, (4,4), output=true)
    # Discontinuous Galerkin
    GridapSWE.run_distributed_benchmark(:DG, dom_params, solver_params, (4,4), output=true)
end