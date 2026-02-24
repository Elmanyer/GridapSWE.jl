# GridapSWE.jl

**GridapSWE** is a high-performance Julia package for solving the **Shallow Water Equations (SWE)** using the [Gridap.jl](https://github.com/gridap/Gridap.jl) finite element ecosystem. This project is optimized for distributed memory parallelism using `GridapDistributed` and `GridapSolvers`.

## 🚀 Features
* **SUPG Stabilization:** Robust handling of advection-dominated flows.
* **Transient Solvers:** Fully integrated with `RungeKutta` methods.
* **Scalable Solvers:** Support for `GridapSolvers` (GMRES + Jacobi/AMG) and `PETSc` backends.
* **MPI Parallelism:** Scalable execution via `PartitionedArrays`.

---

## 🛠️ Installation

1. **Clone the repository:**
   ```bash
   git clone git@github.com:Elmanyer/GridapSWE.jl.git
   cd GridapSWE.jl

   