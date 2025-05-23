using JobQueueMPI
using Test
JQM = JobQueueMPI

mutable struct Message
    value::Int
    vector_idx::Int
end

JQM.enable_debug_messages()

all_jobs_done(controller) = JQM.is_job_queue_empty(controller) && !JQM.any_pending_jobs(controller)

function sum_100(message::Message)
    message.value += 100
    return message
end

function update_data(new_data, message::Message)
    idx = message.vector_idx
    value = message.value
    return new_data[idx] = value
end

function workers_loop()
    if JQM.is_worker_process()
        worker = JQM.Worker()
        while true
            job = JQM.receive_job(worker)
            message = JQM.get_message(job)
            if message == JQM.TerminationMessage()
                break
            end
            return_message = sum_100(message)
            JQM.send_job_answer_to_controller(worker, return_message)
        end
        exit(0)
    end
end

function job_queue(data)
    JQM.mpi_init()
    JQM.mpi_barrier()

    T = eltype(data)
    N = length(data)

    if JQM.is_controller_process() # I am root
        new_data = Array{T}(undef, N)

        controller = JQM.Controller(JQM.num_workers())

        for i in eachindex(data)
            message = Message(data[i], i)
            JQM.add_job_to_queue!(controller, message)
        end

        while !all_jobs_done(controller)
            if !JQM.is_job_queue_empty(controller)
                JQM.send_jobs_to_any_available_workers(controller)
            end
            if JQM.any_pending_jobs(controller)
                job_answer = JQM.check_for_job_answers(controller)
                if !isnothing(job_answer)
                    message = JQM.get_message(job_answer)
                    update_data(new_data, message)
                end
            end
        end

        JQM.send_termination_message()

        return new_data
    end
    workers_loop()
    JQM.mpi_barrier()
    JQM.mpi_finalize()
    return nothing
end

@testset "Sum 100" begin
    data = collect(1:10)
    @test job_queue(data) == [101, 102, 103, 104, 105, 106, 107, 108, 109, 110]
end
