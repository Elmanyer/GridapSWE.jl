using MPI, OpenMPI_jll, PETSc_jll, SCALAPACK32_jll

println("-"^60)
println("MPI.jl:        ", MPI.libmpi)
#println("OpenMPI_jll:   ", OpenMPI_jll.libmpi_path)
println("PETSc_jll:     ", PETSc_jll.libpetsc_path)
println("SCALAPACK32_jll: ", SCALAPACK32_jll.libscalapack32_path)
println("-"^60)

# Check for the dreaded Artifact string
paths = [MPI.libmpi, PETSc_jll.libpetsc_path, SCALAPACK32_jll.libscalapack32_path]
if any(p -> occursin(".julia/artifacts", p), paths)
    println("❌ WARNING: One or more libraries are still leaking from Artifacts!")
else
    println("✅ SUCCESS: All libraries are using system paths.")
end

# Execution in terminal
# julia --project=. check_binary_preferences.jl 