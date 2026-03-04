#!/bin/bash

#SBATCH --job-name="GridapSWE_dx"
#SBATCH --partition=compute
#SBATCH --time=24:00:00
#SBATCH --ntasks-per-node=16
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=3900M
#SBATCH --output=GridapSWE.%j.out
#SBATCH --error=GridapSWE.%j.err

source $HOME/GridapSWE.jl/compile/load_modules_blue.sh

mpiexecjl -n 16 julia --project=$HOME/GridapSWE.jl -J ../GridapSWE_sysimage.so run_SWE_CG_SUPG_distributed_benchmark.jl
