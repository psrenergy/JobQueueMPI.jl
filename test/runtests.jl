using Test
using JobQueueMPI
using MPI
ENV["JULIA_PROJECT"] = dirname(Base.active_project())

JQM = JobQueueMPI

@testset verbose = true "JobQueueMPI Tests" begin
    # mpiexec(exe -> run(`$exe -n 3 $(Base.julia_cmd()) --project test_1.jl`))
    # mpiexec(exe -> run(`$exe -n 3 $(Base.julia_cmd()) --project test_2.jl`))
    mpiexec(exe -> run(`$exe -n 3 $(Base.julia_cmd()) --project test_pmap_mpi.jl`))
    include("test_pmap_serial.jl")
end
