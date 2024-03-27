@enum WorkerStatus begin
    WORKER_BUSY = 0
    WORKER_AVAILABLE = 1
end

mutable struct Worker
    rank::Int
    job_id_running::Int
    Worker() = new(my_rank(), -1)
end

function has_job(worker::Worker)
    MPI.Iprobe(_mpi_comm(); source = controller_rank(), tag = worker.rank + 32)
end

function send_job_answer_to_controller(worker::Worker, message)
    if !is_worker_process()
        error("Only the controller process can send job answers.")
    end
    job = JobAnswer(worker.job_id_running, message)
    return MPI.isend(job, _mpi_comm(); dest = controller_rank(), tag = worker.rank + 32)
end

function receive_job(worker::Worker)
    if !is_worker_process()
        error("Only the controller process can receive jobs.")
    end
    job = MPI.recv(_mpi_comm(); source = controller_rank(), tag = worker.rank + 32)
    worker.job_id_running = job.id
    return job
end
