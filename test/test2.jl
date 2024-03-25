using JobQueueMPI
using Test
JQM = JobQueueMPI

mutable struct ControllerMessage
    value::Int
    vector_idx::Int
end

mutable struct WorkerMessage
    divisors::Array{Int}
    vector_idx::Int
end

function get_divisors(message::ControllerMessage)
    number = message.value
    divisors = []

    for i in 1:number
        if number % i == 0
            push!(divisors, i)
        end
    end

    return JQM.JobAnswer(WorkerMessage(divisors, message.vector_idx))
end

function update_data(new_data, message::WorkerMessage)
    idx = message.vector_idx
    value = message.divisors
    return new_data[idx] = value
end

function divisors(data)
    JQM.mpi_init()
    JQM.mpi_barrier()

    N = length(data)

    if JQM.is_controller_process() # I am root
        new_data = Array{Array{Int}}(undef, N)
        sent_messages = 0
        delivered_messages = 0

        controller = Controller(JQM.num_workers())

        for i in eachindex(data)
            message = ControllerMessage(data[i], i)
            JQM.add_job_to_queue!(controller, message, get_divisors)
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
    else # If rank == worker
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
    JQM.mpi_barrier()
    return JQM.mpi_finalize()
end

@testset "Divisors" begin
    data = [2, 4, 6, 8, 10, 12, 14, 16, 18, 20]
    values = divisors(data)
    @test values[1] == [1, 2]
    @test values[2] == [1, 2, 4]
    @test values[3] == [1, 2, 3, 6]
    @test values[4] == [1, 2, 4, 8]
    @test values[5] == [1, 2, 5, 10]
    @test values[6] == [1, 2, 3, 4, 6, 12]
    @test values[7] == [1, 2, 7, 14]
    @test values[8] == [1, 2, 4, 8, 16]
    @test values[9] == [1, 2, 3, 6, 9, 18]
    @test values[10] == [1, 2, 4, 5, 10, 20]
end
