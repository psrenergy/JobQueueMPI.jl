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
