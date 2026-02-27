#!/bin/bash

#SBATCH --job-name="compile_GridapSWE"
#SBATCH --partition=compute
#SBATCH --time=04:00:00
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=3G
#SBATCH --output=GridapSWE.%j.out
#SBATCH --error=GridapSWE.%j.err

#source load_modules_blue.sh

mpiexecjl -n 1 julia --project=../ compile.jl
