#!/bin/bash

#SBATCH --job-name="runcase_GridapSWE"
#SBATCH --partition=compute
#SBATCH --time=24:00:00
#SBATCH --ntasks-per-node=4
#SBATCH --cpus-per-task=1
#SBATCH --output=SWE_runcase_.%j.out
#SBATCH --error=SWE_runcase_.%j.err

source ../compile/load_modules_blue.sh

mpiexecjl -n 4 julia --project=../ -J ../GridapSWE_ sysimage.so run_SWE_CG_SUPG_distributed_benchmark.jl
