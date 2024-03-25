"""
"""
mutable struct Controller
    n_workers::Int
    debug_mode::Bool
    worker_status::Vector{WorkerStatus}
    job_queue::Vector{Job}
    jobs_sent::Int
    jobs_received::Int
    function Controller(n_workers::Int; debug_mode::Bool = false)
        return new(n_workers, debug_mode, fill(WORKER_AVAILABLE, n_workers), Any[], 0, 0)
    end
end

struct TerminationMessage end

_is_worker_available(controller::Controller, worker::Int) =
    controller.worker_status[worker] == WORKER_AVAILABLE

function _pick_job_to_send!(controller::Controller)
    if _has_jobs_to_send(controller)
        return popfirst!(controller.job_queue)
    else
        error("Controller does not have any jobs to send.")
    end
end

function _has_jobs_to_send(controller::Controller)
    return !isempty(controller.job_queue)
end

function _pick_available_worker(controller::Controller)
    for i in 1:controller.n_workers
        if _is_worker_available(controller, i)
            return i
        end
    end
    return error("No available workers. You should check with any_available_workers() first.")
end

function _pick_available_workers(controller::Controller)
    available_workers = []
    for i in 1:controller.n_workers
        if _is_worker_available(controller, i)
            push!(available_workers, i)
        end
    end
    return available_workers
end

function _any_available_workers(controller::Controller)
    for i in 1:controller.n_workers
        if _is_worker_available(controller, i)
            return true
        end
    end
    return false
end

function add_job_to_queue!(controller::Controller, message::Any, f::Function)
    return push!(controller.job_queue, Job(message, f))
end

function send_job_to_any_available_worker(controller::Controller)
    available_workers = _pick_available_workers(controller)
    requests = Vector{JobRequest}()
    for worker in available_workers
        if _has_jobs_to_send(controller)
            job = _pick_job_to_send!(controller)
            controller.jobs_sent += 1
            controller.worker_status[worker] = WORKER_BUSY
            request = MPI.isend(job, _mpi_comm(); dest = worker, tag = worker + 32)
            push!(requests, JobRequest(worker, request))
        end
    end
    return requests
end

function send_termination_message(controller::Controller)
    requests = Vector{JobRequest}()
    for worker in 1:controller.n_workers
        request = MPI.isend(TerminationMessage(), _mpi_comm(); dest = worker, tag = worker + 32)
        controller.worker_status[worker] = WORKER_TERMINATED
        push!(requests, JobRequest(worker, request))
    end
    return _wait_all(requests)
end

function check_for_workers_job(controller::Controller)
    for worker in 1:controller.n_workers
        has_job = MPI.Iprobe(_mpi_comm(); source = worker, tag = worker + 32)
        if has_job
            job = MPI.recv(_mpi_comm(); source = worker, tag = worker + 32)
            controller.jobs_received += 1
            controller.worker_status[worker] = WORKER_AVAILABLE
            return job
        end
    end
    return nothing
end
