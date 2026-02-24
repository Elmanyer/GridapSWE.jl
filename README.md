# GridapSWE.jl

**GridapSWE** is a high-performance Julia package for solving the **Shallow Water Equations (SWE)** using the [Gridap.jl](https://github.com/gridap/Gridap.jl) finite element ecosystem. This project is optimized for distributed memory parallelism using `GridapDistributed` and `GridapSolvers`.

## 🚀 Features
* **Multiple Weak Formulations:** Discretisation formalism can be selected among several built-in options (`CG`, `CG_SUPG` and `DG`).
* **Transient Solvers:** Fully integrated with `RungeKutta` methods.
* **Scalable Solvers:** Support for `GridapSolvers`.
* **MPI Parallelism:** Scalable execution via `PartitionedArrays`.

---

## 🛠️ Installation

1. **Clone the repository:**

```bash
git clone git@github.com:Elmanyer/GridapSWE.jl.git
cd GridapSWE.jl
```

2. **Instantiate the Environment**

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

---

## ⚡ Acceleration (System Image)

Julia's "Just-In-Time" compilation can introduce significant overhead during benchmarks. We use `PackageCompiler.jl` to create a system image that pre-compiles the heavy FEM kernels and solvers.

1. **Generate the System Image**
Run the provided compilation script. This will execute a short "warmup" simulation to trace and compile the necessary code paths.

```bash
julia --project=. compile/compile.jl
```

This produces GridapSWE_sysimage.so in your root directory.

2. **Run with the System Image**
To start Julia instantly without compilation lag, use the -J flag:

```bash
julia --project=. -J GridapSWE_sysimage.so run/main.jl
```

---

## 💻 Running the Simulation

1. **Sequential Execution**
For standard single-core runs or initial testing, use the following command:
```bash
julia --project=. run/main.jl
```

2. **Distributed Parallel Execution (MPI)**
The solver is designed to scale across multiple CPU cores. To run on 4 processes (adjust the -n flag as needed for your hardware):

```bash
mpiexecjl -n 4 julia --project=. run/main.jl
```

3. **Production Runs (Using System Image)**
To achieve the fastest execution by skipping Julia's JIT compilation phase, use the pre-compiled system image generated in the previous step:

```bash
# Sequential with acceleration
julia --project=. -J GridapSWE_sysimage.so run/main.jl

# Parallel with acceleration (Recommended for Benchmarking)
mpiexecjl -n 4 julia --project=. -J GridapSWE_sysimage.so run/main.jl
```

