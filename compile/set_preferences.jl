using MPIPreferences
using Pkg

# Set MPIPreferences to use the system MPI binary
MPIPreferences.use_system_binary()

# Add specific branches of Gridap and GridapDistributed and GridapSolvers
Pkg.add(PackageSpec(name="Gridap", rev="distributed_AD_transient"))
Pkg.add(PackageSpec(name="GridapDistributed", rev="distributed_AD_transient"))
Pkg.add(PackageSpec(url="https://github.com/Elmanyer/GridapSolvers.jl.git", rev="fix_num_fields"))

# Execution in terminal
# julia --project=. set_preferences.jl

