using MPI

MPI.Init()

comm = MPI.COMM_WORLD
println("Hello world, I am $(MPI.Comm_rank(comm)) of $(MPI.Comm_size(comm))")

# Force a flush to the terminal
flush(stdout)

MPI.Barrier(comm)
MPI.Finalize()