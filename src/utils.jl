@enum WorkerStatus begin
    WORKER_BUSY = 0
    WORKER_AVAILABLE = 1
end

mutable struct Controller
    n_workers::Int
    worker_status::Vector{WorkerStatus}
    workers_requests::Vector{MPI.Request}
    num_scenarios::Int
    messages_sent::Int
    messages_received::Int
    function Controller(n_workers::Int, n_scenarios::Int)
        return new(
            n_workers,
            init_workers_status(n_workers),
            init_workers_requests(n_workers),
            n_scenarios,
            1,
            0,
        )
    end
end

mutable struct Worker
    rank::Int
    status::Vector{WorkerStatus}
    request::Vector{MPI.Request}
    function Worker(rank::Int)
        return new(rank, init_workers_status(1), init_workers_requests(1))
    end
end

mutable struct ControllerMessage
    max_t::Int
    max_s::Int
    t::Int
    s::Int
    solution::Any
    h2_price::Float64
    function ControllerMessage(max_t::Int, max_s::Int, solution::Any, h2_price::Float64)
        return new(max_t, max_s, 1, 1, solution, h2_price)
    end
end

mutable struct WorkerMessage
    cut::Any
    function WorkerMessage(cut::Any)
        return new(cut)
    end
end

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

function reset_message_counters!(controller::Controller)
    controller.messages_sent = 1
    return controller.messages_received = 0
end

function init_workers_requests(n_workers::Int)
    return Array{MPI.Request}(undef, n_workers)
end

function reset_requests!(worker::Worker)
    return worker.request = init_workers_requests(1)
end

save_request!(reqs::Vector{MPI.Request}, worker::Int, request::MPI.Request) = reqs[worker] = request

function init_workers_status(n_workers::Int)
    return [WORKER_AVAILABLE for i in 1:n_workers]
end

_set_worker_status!(worker_status::Vector{WorkerStatus}, worker::Int, status::WorkerStatus) =
    worker_status[worker] = status

_set_worker_available!(controller::Controller, worker::Int) =
    _set_worker_status!(controller.worker_status, worker, WORKER_AVAILABLE)
_set_worker_available!(worker::Worker) = _set_worker_status!(worker.status, 1, WORKER_AVAILABLE)

_set_worker_busy!(controller::Controller, worker::Int) =
    _set_worker_status!(controller.worker_status, worker, WORKER_BUSY)
_set_worker_busy!(worker::Worker) = _set_worker_status!(worker.status, 1, WORKER_BUSY)

_is_request_complete(controller::Controller, worker::Int) = MPI.Test(controller.workers_requests[worker]) == true
_is_request_complete(worker::Worker) = MPI.Test(worker.request[1]) == true

_is_available(worker_status::Vector{WorkerStatus}, worker::Int) = worker_status[worker] == WORKER_AVAILABLE
_is_worker_available(controller::Controller, worker::Int) = _is_available(controller.worker_status, worker)

_is_busy(worker_status::Vector{WorkerStatus}, worker::Int) = worker_status[worker] == WORKER_BUSY
_is_worker_busy(controller::Controller, worker::Int) = _is_busy(controller.worker_status, worker)
_is_worker_busy(worker::Worker) = _is_busy(worker.status, 1)

has_message(idx::Int) = MPI.Iprobe(_mpi_comm(); source = idx, tag = idx + 32) == true
has_message(worker::Worker) = MPI.Iprobe(_mpi_comm(); source = controller_rank(), tag = worker.rank + 32) == true

function has_received_all_messages(controller::Controller)
    return controller.messages_received >= controller.num_scenarios
end

function get_message(controller::Controller, worker::Int)
    controller.messages_received += 1
    @assert controller.messages_received <= controller.num_scenarios
    return MPI.recv(_mpi_comm(); source = worker, tag = worker + 32)
end

function get_message(worker::Worker)
    return MPI.recv(_mpi_comm(); source = controller_rank(), tag = worker.rank + 32)
end

function has_sent_all_messages(controller::Controller)
    return controller.messages_sent > controller.num_scenarios
end

function interrupt_workers()
    requests = Array{MPI.Request}(undef, num_workers())
    for worker in 1:num_workers()
        request = MPI.isend(-1, _mpi_comm(); dest = worker, tag = worker + 32)
        requests[worker] = request
    end
    return MPI.Waitall(requests)
end

function is_queue_done(controller::Controller)
    return has_sent_all_messages(controller) && has_received_all_messages(controller)
end

function _list_available_workers(controller::Controller)
    return [worker for worker in 1:controller.n_workers if controller.worker_status[worker] == WORKER_AVAILABLE]
end

function _list_busy_workers(controller::Controller)
    return [worker for worker in 1:controller.n_workers if controller.worker_status[worker] == WORKER_BUSY]
end

function get_available_workers_to_send(controller::Controller)
    available_workers = Vector{Int}()
    for worker in 1:controller.n_workers
        if _is_worker_available(controller, worker)
            push!(available_workers, worker)
        end
        if length(available_workers) == _remaining_messages_to_send(controller)
            return available_workers
        end
    end
    return available_workers
end

_remaining_messages_to_send(controller::Controller) = controller.num_scenarios - (controller.messages_sent - 1)

function get_available_workers_to_receive(controller::Controller)
    available_workers = Vector{Int}()
    for worker in 1:controller.n_workers
        if _is_worker_available(controller, worker) && has_message(worker)
            push!(available_workers, worker)
        end
        if length(available_workers) == _remaining_messages_to_receive(controller)
            return available_workers
        end
    end
    return available_workers
end

_remaining_messages_to_receive(controller::Controller) = controller.num_scenarios - controller.messages_received

function send_message(controller::Controller, worker::Int, message::ControllerMessage)
    @assert controller.messages_sent <= controller.num_scenarios
    request = MPI.isend(
        [message.solution, message.s, message.t, message.h2_price],
        _mpi_comm();
        dest = worker,
        tag = worker + 32,
    )
    save_request!(controller.workers_requests, worker, request)
    _set_worker_busy!(controller, worker)
    controller.messages_sent += 1
    return iterate_message(message)
end

function send_message(worker::Worker, message::WorkerMessage)
    request = MPI.isend(message.cut, _mpi_comm(); dest = controller_rank(), tag = worker.rank + 32)
    save_request!(worker.request, 1, request)
    return _set_worker_busy!(worker)
end

function iterate_message(message::ControllerMessage)
    if message.s == message.max_s
        message.t += 1
        message.t = 1
    else
        message.s += 1
    end
end

function check_pending_requests(controller::Controller)
    for worker in _list_busy_workers(controller)
        if _is_request_complete(controller, worker)
            _set_worker_available!(controller, worker)
            # else
            #     print("Request not complete for worker: ", worker, "\n")
        end
    end
end

function check_pending_requests(worker::Worker)
    if _is_worker_busy(worker) && _is_request_complete(worker)
        _set_worker_available!(worker)
    end
end
