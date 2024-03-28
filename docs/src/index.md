# JobQueueMPI.jl

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

## API

```@docs
JobQueueMPI.Controller
JobQueueMPI.Worker
JobQueueMPI.add_job_to_queue!
JobQueueMPI.send_jobs_to_any_available_workers
JobQueueMPI.send_termination_message
JobQueueMPI.check_for_job_answers
JobQueueMPI.send_job_answer_to_controller
JobQueueMPI.receive_job
JobQueueMPI.get_message
JobQueueMPI.pmap
```