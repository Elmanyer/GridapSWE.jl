#!/bin/bash

#SBATCH --job-name="SWE_convergence"
#SBATCH --partition=compute
#SBATCH --time=48:00:00
#SBATCH --ntasks-per-node=16
#SBATCH --cpus-per-task=1
#SBATCH --output=SWE_.%j.out
#SBATCH --error=SWE_.%j.err

source ../compile/load_modules_blue.sh

mpiexecjl -n 16 julia --project=../ -J ../GridapSWE_ sysimage.so run_SWE_h_convergence.jl


