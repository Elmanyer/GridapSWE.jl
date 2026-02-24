using Preferences, UUIDs
using MPIPreferences

# Force the system libcurl to load first (bash)
ENV["LD_PRELOAD"] = "/usr/lib/x86_64-linux-gnu/libcurl.so.4"
# export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libcurl.so.4

# Set MPIPreferences to use the system MPI binary, which should be compatible with your OpenMPI 4.1.2 installation. 
# This ensures that the MPI library used by PETSc_jll and OpenMPI_jll matches the one on your system, avoiding symbol conflicts.
MPIPreferences.use_system_binary()

# OpenMPI_jll
set_preferences!(
    UUID("fe0851c0-eecd-5654-98d4-656369965a5c"), 
    "libmpi_path" => "/usr/lib/x86_64-linux-gnu/openmpi/lib/libmpi.so",
    "libmpi_mpifh_path" => "/usr/lib/x86_64-linux-gnu/openmpi/lib/libmpi_mpifh.so",
    force = true
)

# Set PETSc_jll to use the system PETSc library, which should be compatible with your OpenMPI installation.
set_preferences!(
    UUID("8fa3689e-f0b9-5420-9873-adf6ccf46f2d"), # PETSc_jll UUID
    "libpetsc_path" => "/usr/lib/x86_64-linux-gnu/libpetsc_real.so.3.15.5",
    force = true
)

# Set SCALAPACK32_jll to use the system ScaLAPACK library, which should be compatible with your OpenMPI installation. 
# Note: You may need to create a symlink for libscalapack32.so if it doesn't exist, pointing to the appropriate ScaLAPACK 64 bits library on your system.
# sudo ln -s /usr/lib/x86_64-linux-gnu/libscalapack-openmpi.so /usr/lib/x86_64-linux-gnu/libscalapack32.so
set_preferences!(
    UUID("aabda75e-bfe4-5a37-92e3-ffe54af3c273"), # SCALAPACK32_jll UUID
    "libscalapack32_path" => "/usr/lib/x86_64-linux-gnu/libscalapack32.so",
    force = true
)

# Execution in terminal
# julia --project=. set_binary_preferences.jl
