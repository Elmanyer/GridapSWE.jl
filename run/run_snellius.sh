#!/bin/bash

#SBATCH --job-name="runcase_GridapSWE"
#SBATCH --partition=compute
#SBATCH --time=24:00:00
#SBATCH --ntasks-per-node=4
#SBATCH --cpus-per-task=1
#SBATCH --output=GridapSWE.%j.out
#SBATCH --error=GridapSWE.%j.err

#source ../compile/load_modules_snellius.sh

script="run_SWE_CG_SUPG_distributed_benchmark.jl"

mpiexecjl -n 4 julia --project=../ -J ../GridapSWE_sysimage.so $script