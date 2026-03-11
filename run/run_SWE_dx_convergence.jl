
using GridapSWE

# Domain parameters
dom_params = Dict(
        :Lx => 1.0,              # Domain x-axis length
        :Ly => 1.0,              # Domain y-axis length
        :Nx => 10,               # Domain x-axis number of cells
        :Ny => 10)               # Domain y-axis number of cells 

# Solver parameters
solver_params = Dict(
        :dt => 0.001,             # Time step size
        :t0 => 0.0,               # Initial time
        :tF => 0.01,              # Final time
        :tableau => :SDIRK_3_3,   # Butcher tableau for the time-stepping scheme (e.g., SDIRK_3_3 for a 3-stage, 3rd-order SDIRK method)
        :ls_atol => 1e-10,         # Absolute tolerance for the linear solver
        :ls_rtol => 1e-8,         # Relative tolerance for the linear solver
        :ls_maxiter => 1000,      # Maximum number of iterations for the linear solver
        :nls_atol => 1e-9,        # Absolute tolerance for the nonlinear solver
        :nls_rtol => 1e-7,        # Relative tolerance for the nonlinear solver
        :nls_maxiter => 1000,     # Maximum number of iterations for the nonlinear solver
        :Δit => 10)               # Print info every Δit time steps

        
for p in [1, 2, 3, 4]
        for N in [8, 16, 32, 64, 128, 256]
                dom_params[:Nx] = N
                dom_params[:Ny] = N
                # Continuous Galerkin without stabilization
                GridapSWE.run_distributed_benchmark(:CG, dom_params, solver_params, (4,4), output=true, order=p) 
                # Continuous Galerkin with SUPG stabilization
                GridapSWE.run_distributed_benchmark(:CG_SUPG, dom_params, solver_params, (4,4), output=true, order=p)
                # Discontinuous Galerkin
                GridapSWE.run_distributed_benchmark(:DG, dom_params, solver_params, (4,4), output=true, order=p)
        end
end
