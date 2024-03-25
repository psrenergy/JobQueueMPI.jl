@enum WorkerStatus begin
    WORKER_BUSY = 0
    WORKER_AVAILABLE = 1
    WORKER_TERMINATED = 2
end

mutable struct Worker
    rank::Int
    Worker() = new(my_rank())
end

function reset_request(worker::Worker)
    return worker.request = nothing
end

has_job(worker::Worker) =
    MPI.Iprobe(_mpi_comm(); source = controller_rank(), tag = worker.rank + 32) == true

function send_job_to_controller(worker::Worker, job::Any)
    return MPI.isend(job, _mpi_comm(); dest = controller_rank(), tag = worker.rank + 32)
end

receive_job(worker::Worker) =
    MPI.recv(_mpi_comm(); source = controller_rank(), tag = worker.rank + 32)
