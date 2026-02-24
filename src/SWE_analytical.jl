
# SWE_analytical.jl: Analytical manufactured solution for the shallow water equations (SWE)
# This file defines functions for simulating the shallow water equations using the method of manufactured solutions (MMS) in Gridap.

# Fix simulation configuration and parameters
function benchmark_config()
    
    # Benchmark case parameters:
    H0 = 10.0
    U0 = 1.0
    V0 = 0.5
    A = 0.1     # Water depth perturbation amplitude (m)
    B = 0.05    # X-velocity perturbation amplitude (m/s)
    C = 0.05
    Ua, ∂tUa = get_U_analytical(H0, U0, V0, A, B, C)
    Smms = get_Smms(Ua, ∂tUa, F)
    Ua_t(t) = x -> Ua(x,t)
    ∂tUa_t(t) = x -> ∂tUa(x,t)
    Smms_t(t) = x -> Smms(x,t)

    return Ua_t, ∂tUa_t, Smms_t
end


# Analytical manufactured solution
function get_U_analytical(H0, U0, V0, A, B, C)
    # Analytical solution
    Ua(x,t) = begin
        h = H0 + A * (x[1]^2 + x[2]^2) * (1 + t^2)
        u = U0 + B * x[1] * x[2] * t
        v = V0 + C * (x[2] - x[1]) * t
        return VectorValue{Dof}(h, h*u, h*v)
    end
    # Time derivative of the analytical solution
    ∂tUa(x,t) = begin
        h_val = H0 + A * (x[1]^2 + x[2]^2) * (1 + t^2)
        u_val = U0 + B * x[1] * x[2] * t
        v_val = V0 + C * (x[2] - x[1]) * t

        # Clean derivatives
        h_t = A * (x[1]^2 + x[2]^2) * (2*t)
        u_t = B * x[1] * x[2]
        v_t = C * (x[2] - x[1])
        return VectorValue{Dof}(h_t, h_t*u_val + h_val*u_t, h_t*v_val + h_val*v_t)
    end
    return Ua, ∂tUa
end

# Source Term for the Method of Manufactured Solutions (MMS): Smms = ∂tUa + divFUa
function get_Smms(Ua, ∂tUa, F)
    # Flux of analytical solution
    FUa(x,t) = (F∘Ua)(x,t)
    FUa_t(t) = x -> FUa(x,t)
    function divFUa(x,t)
        ∇FUa = ∇(FUa_t(t))(x)                                    # Compute the spatial gradient of the flux with solution state
        ∇FUa_x = VectorValue(1.0,0)⋅(∇FUa⋅VectorValue(1.0,0))    # Get x derivates
        ∇FUa_y = VectorValue(0,1.0)⋅(∇FUa⋅VectorValue(0,1.0))    # Get y derivates
        return ∇FUa_x + ∇FUa_y
    end

    # Manufactured source term: Smms = ∂tUa + divFUa
    Smms(x,t) = ∂tUa(x,t) + divFUa(x,t)
    return Smms
end

########################################################

