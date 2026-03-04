#!/bin/bash

#SBATCH --job-name="runcase_GridapSWE"
#SBATCH --partition=rome
#SBATCH --time=24:00:00
#SBATCH --ntasks-per-node=4
#SBATCH --cpus-per-task=1
#SBATCH --output=GridapSWE.%j.out
#SBATCH --error=GridapSWE.%j.err

source $HOME/GridapSWE.jl/compile/load_modules_snellius.sh

mpiexecjl -n 4 julia --project=$HOME/GridapSWE.jl -J ../GridapSWE_sysimage.so run_SWE_CG_SUPG_distributed_benchmark.jl