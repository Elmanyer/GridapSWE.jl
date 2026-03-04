using MPIPreferences
using Pkg

# Set MPIPreferences to use the system MPI binary
MPIPreferences.use_system_binary()

# Add specific branches of Gridap and GridapDistributed and GridapSolvers
Pkg.add("Gridap#distributed_AD_transient")
Pkg.add("GridapDistributed#distributed_AD_transient")
Pkg.add("https://github.com/Elmanyer/GridapSolvers.jl.git#fix_num_fields")

# Execution in terminal
# julia --project=. set_preferences.jl

