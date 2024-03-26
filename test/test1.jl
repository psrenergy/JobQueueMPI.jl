using JobQueueMPI
using Test
JQM = JobQueueMPI

mutable struct Message
    value::Int
    vector_idx::Int
end

has_messages_to_send(sent_messages, total_messages) = sent_messages < total_messages
has_messages_to_receive(delivered_messages, total_messages) = delivered_messages < total_messages
job_queue_done(sent_messages, delivered_messages, total_messages) =
    sent_messages == total_messages && delivered_messages == total_messages

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
            return_job = sum_100(message)
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
            JQM.add_job_to_queue!(controller, message)
        end

        while !job_queue_done(sent_messages, delivered_messages, N)
            if has_messages_to_send(sent_messages, N)
                requests = JQM.send_jobs_to_any_available_workers(controller)
                sent_messages += length(requests)
            end
            if has_messages_to_receive(delivered_messages, N)
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
    JQM.mpi_finalize()
    return nothing
end

@testset "Sum 100" begin
    data = collect(1:10)
    @test job_queue(data) == [101, 102, 103, 104, 105, 106, 107, 108, 109, 110]
end
