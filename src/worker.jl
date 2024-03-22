@enum WorkerStatus begin
    WORKER_BUSY = 0
    WORKER_AVAILABLE = 1
    WORKER_TERMINATED = 2
end

mutable struct Worker
    rank::Int
end

function workers_loop(f, args...)
    if is_worker_process()
        worker = Worker(my_rank())
        while true
            message = MPI.recv(comm(); source = controller_rank(), tag = worker.rank + 32)
            if message == TerminationMessage()
                break
            end
            message = f(args...)
            send_message_to_controller(worker, message)
        end
    else
        error("This function should only be called by worker processes.")
    end
    return 0
end

function send_message_to_controller(worker::Worker, message::Any)
    return MPI.send(message, _mpi_comm(); dest=controller_rank(), tag=worker.rank + 32)
end