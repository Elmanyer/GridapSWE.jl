

### Gridap Utilities ###

# Define the math for a double contraction between a 3D tensor Ξ(U) and 2D tensor ∇v, resulting in a vector
# Necessary in Gridap Weak Formulation
function contraction(Ξu, ∇v)
    # 1. Define the summation for one component 'i'
    function contract_component(i)
        s = 0.0
        for j in 1:3
            for k in 1:2
                s += Ξu[i,j,k] * ∇v[j,k]
            end
        end
        return s
    end
    # 2. Build the result as a VectorValue of the 3 component sums
    return VectorValue(contract_component(1), contract_component(2), contract_component(3))
end

function get_mesh_sizes(Ω)
    h = CellField(get_cell_measure(Ω),Ω)
    h2 = CellField(lazy_map(dx->dx^(1/2),get_cell_measure(Ω)),Ω)
    return h,h2
end

function get_mesh_sizes(Ω::GridapDistributed.DistributedTriangulation)
    h2map = map(Ω.trians) do trian
        CellField(get_cell_measure(trian),trian)
    end
    h2 = DistributedCellField(h2map,Ω)
    hmap = map(Ω.trians) do trian
        CellField(lazy_map(dx->dx^(1/2),get_cell_measure(trian)),trian)
    end
    h = DistributedCellField(hmap,Ω)
    return h, h2
end

# L2 error
l2(u,dΩ) = sqrt(sum( ∫( u⊙u )*dΩ )) 


function compute_residual_error(tn,  Ua, ∂tUa, Uh, state, odeop, Uₕ, Ω, dΩ)
    # function to compute problem residual and l2 error norms
    ∂tUa_n = interpolate(∂tUa(tn), Uₕ(tn))
    coeffs∂tUa_n = get_free_dof_values(∂tUa_n)

    coeffs = (state[2][2][1], coeffs∂tUa_n)
    odeopcache = allocate_odeopcache(odeop, tn, coeffs)
    odeopcache = update_odeopcache!(odeopcache, odeop, tn)

    # Compute residual
    RUn = residual(odeop, tn, coeffs, odeopcache)
    normUn = norm(RUn)

    # Compute L2 error
    ΔU = Ua(tn) - Uh       # solution error
    L2error = l2(ΔU, dΩ)
    # Compute relative error
    rel_L2error = L2error / l2(CellField(Ua(tn), Ω), dΩ)

    return normUn, L2error, rel_L2error
end


# Write iterative solution and compute errors and residuals
function write_transient_solution_sequential(out_dir, Ua, ∂tUa, odeop, Uh0, Uh, Ω, dΩ, Uₕ, Δit)
    # Input: 
    #   - out_dir -> output directory for vtk files and convergence data
    #   - Ua -> analytical solution function Ua(x,t)
    #   - ∂tUa -> time derivative of the analytical solution function ∂t
    #   - odeop -> algebraic operator of the problem
    #   - Uh0 -> initial FE solution
    #   - Uh -> transient FE solution iterator
    #   - Ω -> FE domain
    #   - dΩ -> FE measure
    #   - Uₕ -> FE space
    #   - Δit -> print info every Δit time steps

    it = 0
    
    # Open convergence file
    mkpath("$out_dir")
    io = open("$out_dir/convergence_data.csv", "w")
    # Print the header
    @printf(io, "%-8s %-12s %-18s %-18s %-18s\n", "Step", "Time", "Residu", "L2_Rel_Err", "L2_Err")

    # VTK file writing environment
    createpvd("$out_dir/sol_nl") do pvd
    
        # Save initial solution
        pvd[0] = createvtk(Ω, "$out_dir/sol_t_0.0000"* ".vtu", cellfields=["u" => Uh0]; append=false)

        #### Iterating through time steps
        local Uhn, tn, state
        # Start the iteration
        next_sol = iterate(Uh)
        # Iterate until end of iterator
        while next_sol !== nothing
            # Update values
            it += 1
            (tn, Uhn), state = next_sol 
            # Compute and print residual and errors every Δit time steps
            if it % Δit == 0 || it == 1
                # Compute residual and errors
                normUn, Uh_L2error, Uh_rel_L2error = compute_residual_error(tn, Ua, ∂tUa, Uhn, state, odeop, Uₕ, Ω, dΩ)

                # Print info
                tn_round = round(tn, digits=4)
                @printf(io, "%-8d %-12.4f %-18.8e %-18.8e %-18.8e\n", it, tn_round, normUn, Uh_rel_L2error, Uh_L2error)
                flush(io)
                println("GridapSWE --| Step $it | Time $tn_round | Residu = $normUn | L2 Rel Error: $Uh_rel_L2error | L2 Error: $Uh_L2error" )

                # Save vtk file with iteration solution
                tn_str = @sprintf("%.4f", tn_round)
                pvd[tn] = createvtk(Ω, "$out_dir/sol_t_$tn_str"* ".vtu", cellfields=["u" => Uhn] ; append=false)
            end
            next_sol = iterate(Uh, state)
        end 
    end

    # Close when finished
    close(io)
    
    return nothing
end


function write_transient_solution_distributed(ranks, out_dir, Ua, ∂tUa, odeop, Uh0, Uh, Ω, dΩ, Uₕ, Δit)
    # Input: 
    #   - ranks -> MPI ranks for distributed environment
    #   - out_dir -> output directory for vtk files and convergence data
    #   - Ua -> analytical solution function Ua(x,t)
    #   - ∂tUa -> time derivative of the analytical solution function ∂t
    #   - odeop -> algebraic operator of the problem
    #   - Uh0 -> initial FE solution
    #   - Uh -> transient FE solution iterator
    #   - Ω -> FE domain
    #   - dΩ -> FE measure
    #   - Uₕ -> FE space
    #   - Δit -> print info every Δit time steps
    it = 0
    
    # Open convergence file
    if i_am_main(ranks) 
        mkpath("$out_dir")
        io = open("$out_dir/convergence_data.csv", "w")
        # Print the header
        @printf(io, "%-8s %-12s %-18s %-18s %-18s\n", "Step", "Time", "Residu", "L2_Rel_Err", "L2_Err")
    end
    MPI.Barrier(MPI.COMM_WORLD)

    # VTK file writing environment
    createpvd(ranks, "$out_dir/sol_nl") do pvd
    
        # Save initial solution
        pvd[0] = createvtk(Ω, "$out_dir/sol_t_0.0000", cellfields=["u" => Uh0]; append=false)

        #### Iterating through time steps
        local Uhn, tn, state
        # Start the iteration
        next_sol = iterate(Uh)
        # Iterate until end of iterator
        while next_sol !== nothing
            # Update values
            it += 1
            (tn, Uhn), state = next_sol 
            # Compute and print residual and errors every Δit time steps
            if it % Δit == 0 || it == 1
                # Compute residual and errors
                normUn, Uh_L2error, Uh_rel_L2error = compute_residual_error(tn, Ua, ∂tUa, Uhn, state, odeop, Uₕ, Ω, dΩ)

                # Print info
                tn_round = round(tn, digits=4)
                if i_am_main(ranks) 
                    @printf(io, "%-8d %-12.4f %-18.8e %-18.8e %-18.8e\n", it, tn_round, normUn, Uh_rel_L2error, Uh_L2error)
                    flush(io)
                    println("GridapSWE --| Step $it | Time $tn_round | Residu = $normUn | L2 Rel Error: $Uh_rel_L2error | L2 Error: $Uh_L2error" )
                end

                # Save vtk file with iteration solution
                tn_str = @sprintf("%.4f", tn_round)
                pvd[tn] = createvtk(Ω, "$out_dir/sol_t_$tn_str", cellfields=["u" => Uhn] ; append=false)
            end
            next_sol = iterate(Uh, state)
        end 
    end

    # Close when finished
    if i_am_main(ranks) 
        close(io)
    end

    return nothing
end

