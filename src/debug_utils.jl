const DEBUG_MODE = Ref{Bool}(false)

function enable_debug_messages()
    return DEBUG_MODE[] = true
end

function disable_debug_messages()
    return DEBUG_MODE[] = false
end

function _is_debug_enabled()
    return DEBUG_MODE[]
end

function _debug_message(message)
    if is_controller_process()
        open("controller_job_queue_mpi.log", "a") do io
            return println(io, "DEBUG (controller): ", message)
        end
    else
        worker_rank = my_rank()
        open("worker_rank_$(worker_rank)_job_queue_mpi.log", "a") do io
            return println(io, "DEBUG (worker $worker_rank): ", message)
        end
    end
end