function mpi_init()
    return MPI.Init()
end

function mpi_finalize()
    return MPI.Finalize()
end

_mpi_comm() = MPI.COMM_WORLD

mpi_barrier() = MPI.Barrier(_mpi_comm())

my_rank() = MPI.Comm_rank(_mpi_comm())

world_size() = MPI.Comm_size(_mpi_comm())

is_running_in_parallel() = world_size() > 1

is_controller_process() = my_rank() == 0

controller_rank() = 0

is_worker_process() = !is_controller_process()

num_workers() = world_size() - 1
