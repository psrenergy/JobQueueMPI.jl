"""
"""
mutable struct Controller
    n_workers::Int
    debug_mode::Bool
    worker_status::Vector{WorkerStatus}
    last_job_id::Int
    job_queue::Vector{Job}
    pending_jobs::Vector{JobRequest}
    function Controller(n_workers::Int; debug_mode::Bool = false)
        return new(n_workers, debug_mode, fill(WORKER_AVAILABLE, n_workers), 0, Vector{Job}(), Vector{JobRequest}())
    end
end

struct TerminationMessage end

_is_worker_available(controller::Controller, worker::Int) =
    controller.worker_status[worker] == WORKER_AVAILABLE

is_job_queue_empty(controller::Controller) = isempty(controller.job_queue)
any_pending_jobs(controller::Controller) = !isempty(controller.pending_jobs)

function any_jobs_left(controller::Controller)
    !is_job_queue_empty(controller) || any_pending_jobs(controller)
end

function _pick_job_to_send!(controller::Controller)
    if !is_controller_process()
        error("Only the controller process can pick jobs to send.")
    end
    if !is_job_queue_empty(controller)
        return popfirst!(controller.job_queue)
    else
        error("Controller does not have any jobs to send.")
    end
end

function _pick_available_workers(controller::Controller)
    if !is_controller_process()
        error("Only the controller process can pick available workers.")
    end
    available_workers = []
    for i in 1:controller.n_workers
        if _is_worker_available(controller, i)
            push!(available_workers, i)
        end
    end
    return available_workers
end

function add_job_to_queue!(controller::Controller, message::Any)
    if !is_controller_process()
        error("Only the controller process can add jobs to the queue.")
    end
    controller.last_job_id += 1
    return push!(controller.job_queue, Job(controller.last_job_id, message))
end

function send_jobs_to_any_available_workers(controller::Controller)
    if !is_controller_process()
        error("Only the controller process can send jobs to workers.")
    end
    available_workers = _pick_available_workers(controller)
    for worker in available_workers
        if !is_job_queue_empty(controller)
            job = _pick_job_to_send!(controller)
            controller.worker_status[worker] = WORKER_BUSY
            request = MPI.isend(job, _mpi_comm(); dest = worker, tag = worker + 32)
            push!(controller.pending_jobs, JobRequest(worker, request))
        end
    end
    return nothing
end

function send_termination_message(controller::Controller)
    if !is_controller_process()
        error("Only the controller process can send termination messages.")
    end
    requests = Vector{JobRequest}()
    for worker in 1:controller.n_workers
        request = MPI.isend(Job(controller.last_job_id, TerminationMessage()), _mpi_comm(); dest = worker, tag = worker + 32)
        controller.worker_status[worker] = WORKER_AVAILABLE
        push!(requests, JobRequest(worker, request))
    end
    return _wait_all(requests)
end

function check_for_job_answers(controller::Controller)
    if !is_controller_process()
        error("Only the controller process can check for workers' jobs.")
    end
    for j_i in eachindex(controller.pending_jobs)
        worker_completed_a_job = MPI.Iprobe(
            _mpi_comm();
            source = controller.pending_jobs[j_i].worker,
            tag = controller.pending_jobs[j_i].worker + 32,
        )
        if worker_completed_a_job
            job_answer = MPI.recv(
                _mpi_comm();
                source = controller.pending_jobs[j_i].worker,
                tag = controller.pending_jobs[j_i].worker + 32,
            )
            controller.worker_status[controller.pending_jobs[j_i].worker] = WORKER_AVAILABLE
            deleteat!(controller.pending_jobs, j_i)
            return job_answer
        end
    end
    return nothing
end
