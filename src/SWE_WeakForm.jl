
# SWE_WeakForm.jl: Weak formulations for the shallow water equations (SWE) solver in Gridap.
# This file defines the weak formulations for the shallow water equations (SWE) solver using different numerical schemes (CG, CG_SUPG, DG) in Gridap.
# It includes the definition of the flux function, its Jacobian and divergence for an arbitrary state.

# Shallow Water Equations Flux 
function F(U)
    U1 = U⋅VectorValue{Dof,Float64}(1,0,0)
    U2 = U⋅VectorValue{Dof,Float64}(0,1,0)
    U3 = U⋅VectorValue{Dof,Float64}(0,0,1)
    return TensorValue{Dof, Dim}(U2, U2^2/U1 + 0.5*g*U1^2, U2*U3/U1, 
                                    U3, U2*U3/U1, U3^2/U1 + 0.5*g*U1^2 )
end 

# Shallow Water Equations Flux Jacobian: Jacobian matrix of the flux function F with respect to the solution variables U
Ξ(U) = ∇(F)(U)

# Arbitrary solution flux divergence
function divF(U)
    ∇FU = (∇(U)⋅(Ξ∘U))
    ∇FU_x = VectorValue(1.0,0)⋅(∇FU⋅VectorValue(1.0,0))    # Get x derivates
    ∇FU_y = VectorValue(0,1.0)⋅(∇FU⋅VectorValue(0,1.0))    # Get y derivates
    return ∇FU_x + ∇FU_y
end


function SWE_CG_formulation(model, reffe, Ug, Source, degree)

    Vₕ = TestFESpace(model,reffe;conformity=:H1,dirichlet_tags=["boundary"])
    Uₕ = TransientTrialFESpace(Vₕ, Ug)
    # Numerical integration
    Ω = Triangulation(model)
    dΩ = Measure(Ω,degree)

    ######## WEAK FORMULATION ########
    # Continuous Galerkin formulation
    A(t, u, v) = ∫( v⋅∂t(u) - ∇(v)' ⊙ (F∘u) )dΩ 
    B(t, v) = ∫( v⋅Source(t) )dΩ

    # Residual weak form
    res(t,u,v) = A(t,u,v) - B(t,v)

    return Ω, dΩ, Uₕ, Vₕ, res
end


function SWE_CG_SUPG_formulation(model, reffe, Ug, Source, degree)

    Vₕ = TestFESpace(model,reffe;conformity=:H1,dirichlet_tags=["boundary"])
    Uₕ = TransientTrialFESpace(Vₕ, Ug)
    # Numerical integration
    Ω = Triangulation(model)
    dΩ = Measure(Ω,degree)

    ######## WEAK FORMULATION ########
    # Continuous Galerkin formulation
    A_CG(t, u, v) = ∫( v⋅∂t(u) - ∇(v)' ⊙ (F∘u) )dΩ 
    B_CG(t, v) = ∫( v⋅Source(t) )dΩ
    # Residual strong form
    R(t,u) = ∂t(u) + divF(u) - Source(t)

    # SUPG stabilization
    αₜ = 0.5
    h, Aₑ = get_mesh_sizes(Ω)
    function τau(U)
        U1 = U⋅VectorValue{Dof,Float64}(1,0,0)
        U2 = U⋅VectorValue{Dof,Float64}(0,1,0)
        U3 = U⋅VectorValue{Dof,Float64}(0,0,1)
        return 1 / sqrt( (U2/U1)^2 + (U3/U1)^2 + g*abs(U1) )
    end
    SUPG(t,u,v) = ∫( αₜ * Aₑ * Operation(τau)(u) * (R(t,u)⋅(Operation(contraction)(Ξ∘u, ∇(v)'))) )dΩ
    A_SUPG(t,u,v) = A_CG(t,u,v) + SUPG(t,u,v)

    # Residual weak form
    res(t,u,v) = A_SUPG(t,u,v) - B_CG(t,v)

    return Ω, dΩ, Uₕ, Vₕ, res
end


function SWE_DG_formulation(model, reffe, Ug, Source, degree) 

    Vₕ = TestFESpace(model,reffe;conformity=:L2)
    Uₕ = TransientTrialFESpace(Vₕ)
    # Numerical integration
    # on domain Ω
    Ω = Triangulation(model)
    dΩ = Measure(Ω,degree)
    # on domain boundaries Γin and Γout
    Γ = BoundaryTriangulation(model)
    nΓ = get_normal_vector(Γ)
    dΓ = Measure(Γ,degree)

    # on interior facets skeleton mesh
    Λ = SkeletonTriangulation(model)
    nΛ = get_normal_vector(Λ)
    dΛ = Measure(Λ,degree)

    ######## WEAK FORMULATION ########
    invdF_Γ = 1.0 ./ CellField(get_cell_measure(Γ),Γ)
    invdF_Λ = 1.0 ./ CellField(get_cell_measure(Λ),Λ)
    #λ = order * (order + 1.0)
    λ = 10.0

    # Weak Form Bulk terms
    A_Ω(t, u, v) = ∫( v.⁺⋅∂t(u.⁺) - ∇(v.⁺)' ⊙ (F∘u.⁺) )dΩ 
    B_Ω(t, v) = ∫( v.⁺⋅(Source(t)) )dΩ

    # Weak Form Boundary terms
    A_Γ(t, u, v) = ∫( 0.5 * (v.⁺⋅((F∘u.⁺)⋅nΓ)) + (λ * invdF_Γ * u.⁺⋅v.⁺) )dΓ  
    B_Γ(t, v)    = ∫( - 0.5 * (v.⁺⋅((F∘Ug(t))⋅nΓ)) + (λ * invdF_Γ * Ug(t)⋅v.⁺) )dΓ

    # Weak Form Interior facets terms
    A_Λ(t, u, v) = ∫( ( jump(v)⋅(0.5 * (F∘u.⁺ + F∘u.⁻) ⋅ nΛ.⁺) ) + (λ * invdF_Λ * jump(v)⋅jump(u)) )dΛ 

    # Residual weak form
    res(t,u,v) = A_Ω(t,u,v) + A_Γ(t,u,v) + A_Λ(t,u,v) - (B_Ω(t,v) + B_Γ(t,v))

    return Ω, dΩ, Uₕ, Vₕ, res
end