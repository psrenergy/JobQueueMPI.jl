using Test
using JobQueueMPI
using MPI
ENV["JULIA_PROJECT"] = dirname(Base.active_project())

JQM = JobQueueMPI

@testset verbose = true "JobQueueMPI Tests" begin
    run(`$(mpiexec()) -n 3 $(Base.julia_cmd()) --project test_1.jl`)
    run(`$(mpiexec()) -n 3 $(Base.julia_cmd()) --project test_2.jl`)
    run(`$(mpiexec()) -n 3 $(Base.julia_cmd()) --project test_pmap_mpi.jl`)
    run(`$(mpiexec()) -n 3 $(Base.julia_cmd()) --project test_pmap_mpi_optim.jl`)
    include("test_pmap_serial.jl")
end
