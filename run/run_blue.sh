#!/bin/bash

#SBATCH --job-name="GridapSWE_dx"
#SBATCH --partition=compute
#SBATCH --time=48:00:00
#SBATCH --ntasks-per-node=16
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=3900M
#SBATCH --output=GridapSWE.%j.out
#SBATCH --error=GridapSWE.%j.err

source ../compile/load_modules_blue.sh

script="../run/run_SWE_dx_convergence.jl"

mpiexecjl -n 16 julia --project=../ -J ../GridapSWE_sysimage.so $script
