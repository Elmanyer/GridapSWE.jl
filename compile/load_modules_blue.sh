
module load 2024r1 slurm openmpi julia

export MPI_LIB_DIR=$(mpicc --showme:libdirs | awk '{print $1}')
export LD_LIBRARY_PATH=$MPI_LIB_DIR:$LD_LIBRARY_PATH