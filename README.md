# JobQueueMPI.jl

[build-img]: https://github.com/psrenergy/JobQueueMPI.jl/actions/workflows/test.yml/badge.svg?branch=master
[build-url]: https://github.com/psrenergy/JobQueueMPI.jl/actions?query=workflow%3ACI

[codecov-img]: https://codecov.io/gh/psrenergy/JobQueueMPI.jl/coverage.svg?branch=master
[codecov-url]: https://codecov.io/gh/psrenergy/JobQueueMPI.jl?branch=master

| **Build Status** | **Coverage** | 
|:-----------------:|:-----------------:|
| [![Build Status][build-img]][build-url] | [![Codecov branch][codecov-img]][codecov-url] |[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://psrenergy.github.io/JobQueueMPI.jl/dev/)


JobQueueMPI.jl is a Julia package that provides a simplified interface for running multiple jobs in parallel using [MPI.jl](https://github.com/JuliaParallel/MPI.jl).

It uses the Job Queue concept to manage the jobs and the MPI processes. The user can add jobs to the queue and the package will take care of sending them to the available MPI processes.

## Installation

You can install JobQueueMPI.jl using the Julia package manager. From the Julia REPL, type `]` to enter the Pkg REPL mode and run:

```julia
pkg> add JobQueueMPI
```

## How it works

First, when running a program using MPI, the user has to set the number of processes that will parallelize the computation. One of these processes will be the controller, and the others will be the workers.

We can easily delimit the areas of the code that will be executed only by the controller or the worker.

JobQueueMPI.jl has the following components:

- `Controller`: The controller is responsible for managing the jobs and the workers. It keeps track of the jobs that have been sent and received and sends the jobs to the available workers.
- `Worker`: The worker is responsible for executing the jobs. It receives the jobs from the controller, executes them, and sends the results back to the controller.

Users can call functions to compute jobs in parallel in two ways:
 - Building a function and using a `pmap` implementation that will put the function in the job queue and send it to the workers.
```julia
using JobQueueMPI

function sum_100(value)
    return value + 100
end

sum_100_answer = JobQueueMPI.pmap(sum_100, collect(1:10))
```
 - Building the jobs and sending them to workers explicitly. There are examples of this structure in the test folder. This way is much more flexible than the first one, but it requires more code and knowledge about how MPI works.

```julia
using JobQueueMPI

mutable struct Message
    value::Int
    vector_idx::Int
end

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

    if JQM.is_controller_process()
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

data = collect(1:10)
new_data = job_queue(data)
```