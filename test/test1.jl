using JobQueueMPI
using Test
JQM = JobQueueMPI

mutable struct Message
    value::Int
    vector_idx::Int
end

function sum_100(message::Message)
    message.value += 100
    return JobAnswer(message)
end

function update_data(new_data, message::Message)
    idx = message.vector_idx
    value = message.value
    return new_data[idx] = value
end

function workers_loop()
    if JQM.is_worker_process()
        worker = Worker()
        while true
            job = JQM.receive_job(worker)
            if job == TerminationMessage()
                break
            end
            message = JQM.get_message(job)
            job_task = JQM.get_task(job)
            return_job = job_task(message)
            JQM.send_job_to_controller(worker, return_job)
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
        sent_messages = 0
        delivered_messages = 0

        controller = Controller(JQM.num_workers())

        for i in eachindex(data)
            message = Message(data[i], i)
            JQM.add_job_to_queue!(controller, message, sum_100)
        end

        while sent_messages < N || delivered_messages < N
            if sent_messages < N
                if JQM.send_job_to_any_available_worker(controller)
                    sent_messages += 1
                end
            end
            if delivered_messages < N
                job_answer = JQM.check_for_workers_job(controller)
                if !isnothing(job_answer)
                    message = JQM.get_message(job_answer)
                    update_data(new_data, message)
                    delivered_messages += 1
                end
            end
        end

        JQM.send_termination_message(controller)

        return new_data
    end
    workers_loop()
    JQM.mpi_barrier()
    return JQM.mpi_finalize()
end

@testset "Sum 100" begin
    data = collect(1:10)
    @test job_queue(data) == [101, 102, 103, 104, 105, 106, 107, 108, 109, 110]
end
