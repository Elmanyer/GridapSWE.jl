using MPIPreferences
using Pkg

# Set MPIPreferences to use the system MPI binary
#MPIPreferences.use_system_binary()
### DelftBlue
#MPIPreferences.use_system_binary(library_names=["/apps/arch/2024r1/software/linux-rhel8-cascadelake/gcc-11.3.0/openmpi-4.1.6-w6w5qi5ljesbctyoojlfialbynqt25jb/lib/libmpi.so"])
### Snellius
MPIPreferences.use_system_binary(library_names=["/sw/arch/RHEL9/EB_production/2024/software/OpenMPI/5.0.3-GCC-13.3.0/lib/libmpi.so"])

# Add specific branches of Gridap and GridapDistributed and GridapSolvers
Pkg.add([PackageSpec(name="Gridap", rev="distributed_AD_transient"),
         PackageSpec(name="GridapDistributed", rev="distributed_AD_transient"),
         PackageSpec(url="https://github.com/Elmanyer/GridapSolvers.jl.git", rev="fix_num_fields")
        ])
Pkg.instantiate()

# Execution in terminal
# julia --project=. set_preferences.jl

