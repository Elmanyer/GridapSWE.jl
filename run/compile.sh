#!/bin/bash

#SBATCH --job-name="compile_GridapSWE"
#SBATCH --partition=compute
#SBATCH --time=04:00:00
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --output=compile_GridapSWE_.%j.out
#SBATCH --error=compile_GridapSWE_.%j.err

source ../compile/load_modules_blue.sh

mpiexecjl -n 1 julia --project=../ ../compile/compile.jl
