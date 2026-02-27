using MPIPreferences

# Set MPIPreferences to use the system MPI binary
MPIPreferences.use_system_binary()

# Execution in terminal
# julia --project=. set_binary_preferences.jl


#add Gridap#distributed_AD_transient GridapDistributed#distributed_AD_transient
#add https://github.com/Elmanyer/GridapSolvers.jl.git#fix_num_fields
