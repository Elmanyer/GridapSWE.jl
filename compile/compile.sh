#!/bin/bash

#SBATCH --job-name="compile_GridapSWE"
#SBATCH --partition=compute
#SBATCH --time=04:00:00
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=4G
#SBATCH --output=GridapSWE.%j.out
#SBATCH --error=GridapSWE.%j.err

source load_modules_blue.sh

srun -n 1 julia --project=../ -e 'using MPI; MPI.Init(); include("compile.jl"); MPI.Finalize()'
