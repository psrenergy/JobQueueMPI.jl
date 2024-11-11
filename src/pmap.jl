function _p_map_workers_loop(f, data_defined_in_process)
    if is_worker_process()
        worker = Worker()
        while true
            job = receive_job(worker)
            message = get_message(job)
            if message == TerminationMessage()
                break
            end
            answer_message = if data_defined_in_process === nothing
                f(message)
            else
                f(data_defined_in_process, message)
            end
            send_job_answer_to_controller(worker, answer_message)
        end
    end
    return nothing
end

"""
    pmap(
        f::Function, 
        jobs::Vector, 
        data_defined_in_process = nothing; 
        return_result_in_all_processes::Bool = false
    )

Parallel map function that works with MPI. If the function is called in parallel, it will
distribute the jobs to the workers and collect the results. If the function is called in
serial, it will just map the function to the jobs.

The function `f` should take one argument, which is the message to be processed. If `data_defined_in_process`
is not `nothing`, the function `f` should take two arguments, the first one being `data_defined_in_process`.

The `return_result_in_all_processes` argument is used to broadcast the result to all processes. If set to `true`.

The controller process will return the answer in the same order as the jobs were given. The workers will
return nothing.
"""
function pmap(
    f::Function,
    jobs::Vector,
    data_defined_in_process = nothing;
    return_result_in_all_processes::Bool = true,
)
    result = Vector{Any}(undef, length(jobs))
    if is_running_in_parallel()
        mpi_barrier()
        if is_controller_process()
            controller = Controller(num_workers())
            for job in jobs
                add_job_to_queue!(controller, job)
            end
            while any_jobs_left(controller)
                if !is_job_queue_empty(controller)
                    send_jobs_to_any_available_workers(controller)
                end
                if any_pending_jobs(controller)
                    job_answer = check_for_job_answers(controller)
                    if !isnothing(job_answer)
                        message = get_message(job_answer)
                        job_id = job_answer.job_id
                        result[job_id] = message
                    end
                end
            end
            send_termination_message()
            mpi_barrier()
            if return_result_in_all_processes
                result = MPI.bcast(result, controller_rank(), MPI.COMM_WORLD)
                mpi_barrier()
            end
            return result
        else
            _p_map_workers_loop(f, data_defined_in_process)
            mpi_barrier()
            if return_result_in_all_processes
                result = MPI.bcast(result, controller_rank(), MPI.COMM_WORLD)
                mpi_barrier()
            end
            return result
        end
    else
        for (i, job) in enumerate(jobs)
            result[i] = if data_defined_in_process === nothing
                f(job)
            else
                f(data_defined_in_process, job)
            end
        end
        return result
    end
    return error("Should never get here")
end
