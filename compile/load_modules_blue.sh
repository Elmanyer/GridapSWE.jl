
module load 2022r2 openmpi intel-mkl

export JULIA_MPI_BINARY=system
export JULIA_MPI_PATH=/mnt/shared/apps/2022r2/compute/linux-rhel8-skylake_avx512/gcc-8.5.0/openmpi-4.1.1-urzuzcvzrdedifi3mm527t4wgiisuvld
export JULIA_MPIEXEC=srun