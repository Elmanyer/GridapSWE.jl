module GridapSWE

# Module for the Shallow Water Equations (SWE) model, which includes the implementation of the SWE solver using:
# - the Continuous Galerkin method with Streamline Upwind Petrov-Galerkin (SUPG) stabilization. 
# - the Discontinuous Galerkin method with Penalty Method. 

# Load basic Julia utilities
using Printf

# Load Gridap
using Gridap
using Gridap.Geometry
using Gridap.ReferenceFEs
using Gridap.TensorValues
using Gridap.FESpaces
using Gridap.Algebra
using Gridap.ODEs
using GridapDistributed
using GridapDistributed: DistributedTriangulation, DistributedCellField
using PartitionedArrays
using GridapSolvers
using GridapSolvers.NonlinearSolvers, GridapSolvers.LinearSolvers
using LineSearches: BackTracking
using MPI

# Execution command: 
# mpiexec -n 6 julia --project=. SWE_fullboundary_CG_SUPG_distributed_benchmark.jl

# Fix problem parameters for the Shallow Water Equations model
const Dim = 2     # Spatial dimension
const Dof = 3     # Number of degrees of freedom
const g = 9.81    # Gravitational acceleration

# Script containing SWE generic formalism (flux function, flux divengence...) and Method of Manufactured Solution (MMS) formulation for benchmarking
include("SWE_analytical.jl")

# Gridap utilities for the SWE solver
include("GridapUtilities.jl")

# Weak formulations for the SWE solver
include("SWE_WeakForm.jl")


# Main function for sequential execution
function run_sequential_benchmark(scheme::Symbol, dom_params, solver_params; output=false, order=3, degree=6)
    # Input:
    #   - scheme -> numerical scheme to solve the SWE
    #   - dom_params -> dictionary of domain parameters (Lx, Ly, Nx, Ny)
    #   - solver_params -> dictionary of solver parameters (Δt, t0, tF, tableau)

    # Get benchmark case configuration
    Ua, ∂tUa, Smms = benchmark_config()

    # Create output directory
    if output
        Δx = round(dom_params[:Lx] / dom_params[:Nx], digits=4)
        output_dir = "output/SWE_fullboundary_CG_SUPG_benchmark_Δx_$(Δx)_output"
        if !isdir(output_dir)
            mkpath(output_dir)
        end
    else
        output_dir = nothing
    end

    ########## DISCRETIZE DOMAIN ##########
    # Define the distributed model and spaces
    domain = (0.0, dom_params[:Lx], 0.0, dom_params[:Ly])
    partition = (dom_params[:Nx],dom_params[:Ny])
    model = UnstructuredDiscreteModel(CartesianDiscreteModel(domain,partition))
    reffe = ReferenceFE(lagrangian,VectorValue{Dof,Float64},order)

    # Write the model to file
    if !isnothing(output_dir)
        mkpath("$output_dir/model")
        writevtk(model,"$output_dir/model/model" ; append=false)
    end

    ######## SELECT WEAK FORMULATION ########
    if scheme == :CG
        Ω, dΩ, Uₕ, Vₕ, res = SWE_CG_formulation(model, reffe, Ua, Smms, degree)
    elseif scheme == :CG_SUPG
        Ω, dΩ, Uₕ, Vₕ, res = SWE_CG_SUPG_formulation(model, reffe, Ua, Smms, degree)
    elseif scheme == :DG
        Ω, dΩ, Uₕ, Vₕ, res = SWE_DG_formulation(model, reffe, Ua, Smms, degree)
    else
        error("Unknown numerical scheme: $(scheme). Supported schemes are :CG, :CG_SUPG, and :DG.")
    end

    # Define the transient FE operator for the problem
    op = TransientFEOperator(res,Uₕ,Vₕ)
    odeop = get_algebraic_operator(op)

    ############## SOLVER #############
    lin_solver = LUSolver()
    nl_solver = NLSolver(lin_solver, method=:newton, iterations=20, show_trace=false)
    solver = RungeKutta(nl_solver, lin_solver, solver_params[:Δt], solver_params[:tableau])
    Uh0 = interpolate_everywhere(Ua(solver_params[:t0]), Uₕ(solver_params[:t0]))

    Uh = solve(solver, op, solver_params[:t0], solver_params[:tF], Uh0)

    ############# ITERATE #############
    # Iterate through the solution and compute errors, residuals, and save vtk files
    if !isnothing(output_dir)
        solution_dir = output_dir * "/solver_" * string(solver_params[:tableau]) * "_tf_$(solver_params[:tF])_Δt_$(solver_params[:Δt])"
        write_transient_solution_sequential(solution_dir, Ua, ∂tUa, odeop, Uh0, Uh, Ω, dΩ, Uₕ, solver_params[:Δit])
    
    # Iterate without writing output
    else
        # Loop until the end of the iterator
        local UhF, tF, state
        # Start the iteration
        next_sol = iterate(Uh)
        # Iterate until end of iterator
        while next_sol !== nothing 
            (tF, UhF), state = next_sol 
            next_sol = iterate(Uh, state)
        end
        # Print final solution residu and L2 error
        normUn, L2error, rel_L2error = compute_residual_error(tF,  Ua, ∂tUa, UhF, state, odeop, Uₕ, Ω, dΩ)
        println("GridapSWE --| End time: $tF  | Residu = $normUn | L2 Rel Error: $rel_L2error | L2 Error: $L2error" )
    end
    return nothing
end

# Main function for distributed execution
function run_distributed_benchmark(scheme::Symbol, dom_params, solver_params, cpu_grid; output=false, order=3, degree=6)
    # Input:
    #   - scheme -> numerical scheme to solve the SWE
    #   - dom_params -> dictionary of domain parameters (Lx, Ly, Nx, Ny)
    #   - solver_params -> dictionary of solver parameters (Δt, t0, tF, tableau)
    #   - cpu_grid -> tuple with the grid of distributed processes (e.g., (2,3) for a 2x3 grid)

    with_mpi() do distribute
        # Get benchmark case configuration
        Ua, ∂tUa, Smms = benchmark_config()

        # Get the distributed ranks for the current process
        ranks = distribute(LinearIndices((prod(cpu_grid),)))

        if output 
            Δx = round(dom_params[:Lx] / dom_params[:Nx], digits=4)
            output_dir = "output/SWE_fullboundary_CG_SUPG_benchmark_Δx_$(Δx)_output"
            if i_am_main(ranks) && !isdir(output_dir)
                mkpath(output_dir)
            end
        else
            output_dir = nothing
        end
        MPI.Barrier(MPI.COMM_WORLD) 

        ########## DISCRETIZE DOMAIN ##########
        domain = (0.0, dom_params[:Lx], 0.0, dom_params[:Ly])
        partition = (dom_params[:Nx],dom_params[:Ny])
        model = UnstructuredDiscreteModel(CartesianDiscreteModel(ranks, cpu_grid, domain,partition))
        reffe = ReferenceFE(lagrangian,VectorValue{Dof,Float64},order)

        # Use the PartitionedArrays helper to run only on the "root" rank (usually rank 1)
        if !isnothing(output_dir) 
            if i_am_main(ranks)
                mkpath("$output_dir/model")
            end
            # Wait for the root rank to finish creating the directory before others proceed
            MPI.Barrier(MPI.COMM_WORLD)
            # Write the model to file
            writevtk(model,"$output_dir/model/model" ; append=false)
        end

        ######## SELECT WEAK FORMULATION ########
        if scheme == :CG
            Ω, dΩ, Uₕ, Vₕ, res = SWE_CG_formulation(model, reffe, Ua, Smms, degree)
        elseif scheme == :CG_SUPG
            Ω, dΩ, Uₕ, Vₕ, res = SWE_CG_SUPG_formulation(model, reffe, Ua, Smms, degree)
        elseif scheme == :DG
            Ω, dΩ, Uₕ, Vₕ, res = SWE_DG_formulation(model, reffe, Ua, Smms, degree)
        else
            error("Unknown numerical scheme: $(scheme). Supported schemes are :CG, :CG_SUPG, and :DG.")
        end

        # Define the transient FE operator for the problem
        op = TransientFEOperator(res, Uₕ,Vₕ)
        odeop = get_algebraic_operator(op)

        ############## SOLVER #############
        lin_solver = GMRESSolver(1000,Pr=JacobiLinearSolver(),atol=solver_params[:ls_atol],rtol=solver_params[:ls_rtol],maxiter=solver_params[:ls_maxiter],verbose=false)
        nl_solver = NewtonSolver(lin_solver, maxiter=solver_params[:nls_maxiter],atol=solver_params[:nls_atol],rtol=solver_params[:nls_rtol],verbose=false)

        solver = RungeKutta(nl_solver, lin_solver, solver_params[:Δt], solver_params[:tableau])
        Uh0 = interpolate_everywhere(Ua(solver_params[:t0]), Uₕ(solver_params[:t0]))

        Uh = solve(solver, op, solver_params[:t0], solver_params[:tF], Uh0)

        ############# ITERATE #############
        # Iterate through the solution and compute errors, residuals, and save vtk files
        if !isnothing(output_dir)
            solution_dir = output_dir * "/solver_" * string(solver_params[:tableau]) * "_tf_$(solver_params[:tF])_Δt_$(solver_params[:Δt])"
            write_transient_solution_distributed(ranks, solution_dir, Ua, ∂tUa, odeop, Uh0, Uh, Ω, dΩ, Uₕ, solver_params[:Δit])

        # Iterate without writing output
        else
            # Loop until the end of the iterator
            local UhF, tF, state
            # Start the iteration
            next_sol = iterate(Uh)
            # Iterate until end of iterator
            while next_sol !== nothing 
                (tF, UhF), state = next_sol 
                next_sol = iterate(Uh, state)
            end
            # Print final solution residu and L2 error
            normUn, L2error, rel_L2error = compute_residual_error(tF,  Ua, ∂tUa, UhF, state, odeop, Uₕ, Ω, dΩ)
            if i_am_main(ranks)
                println("GridapSWE --| End time: $tF | Residu = $normUn | L2 Rel Error: $rel_L2error | L2 Error: $L2error" )
            end
        end
        
    end
    return nothing
end

end # module GridapSWE
