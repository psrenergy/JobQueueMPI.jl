"""
"""
mutable struct Controller
    n_workers::Int
    debug_mode::Bool
    worker_status::Vector{WorkerStatus}
    job_queue::Vector{Any}
    messages_sent::Int
    messages_received::Int
    function Controller(n_workers::Int; debug_mode::Bool=false)
        return new(
            n_workers,
            debug_mode,
            fill(WORKER_AVAILABLE, n_workers),
            Any[],
            0,
            0,
        )
    end
end

struct TerminationMessage end

function _pick_message_to_send!(controller::Controller)
    return popfirst!(controller.job_queue)
end

function _pick_available_worker(controller::Controller)
    for i in 1:controller.n_workers
        if _is_worker_available(controller, i)
            return i
        end
    end
    error("No available workers. You should check with any_available_workers() first.")
end

function _any_available_workers(controller::Controller)
    for i in 1:controller.n_workers
        if _is_worker_available(controller, i)
            return true
        end
    end
    return false
end

function _has_message_to_send(controller::Controller)
    return !isempty(controller.job_queue)
end

function add_message_to_queue!(controller::Controller, message::Any)
    push!(controller.job_queue, message)
end

function send_message_to_any_available_worker_worker(controller::Controller)
    if _has_message_to_send(controller) && any_available_workers(controller)
        worker = _pick_available_worker(controller)
        message = _pick_message_to_send!(controller)
        controller.messages_sent += 1
        controller.worker_status[worker] = WORKER_BUSY
        MPI.isend(message, _mpi_comm(); dest=worker, tag=worker + 32)
    end
end

function send_termination_message(controller::Controller)
    for worker in 1:controller.n_workers
        MPI.isend(TerminationMessage(), _mpi_comm(); dest=worker, tag=worker + 32)
        controller.worker_status[worker] = WORKER_TERMINATED
    end
end

function check_for_workers_message(controller::Controller)
    message = nothing
    for worker in 1:controller.n_workers
        has_message = MPI.Iprobe(comm(); source = worker, tag = worker + 32)
        if has_message
            message = MPI.recv(comm(); source = worker, tag = worker + 32)
            controller.messages_received += 1
            controller.worker_status[worker] = WORKER_AVAILABLE
            break
        end
    end
    return message
end