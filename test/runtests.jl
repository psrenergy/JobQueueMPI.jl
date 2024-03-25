using Test
using JobQueueMPI
using MPI
ENV["JULIA_PROJECT"] = dirname(Base.active_project())

JQM = JobQueueMPI

@testset verbose = true "JobQueueMPI Tests" begin
    mpiexec(exe -> run(`$exe -n 3 $(Base.julia_cmd()) --project .\\test1.jl`))
    mpiexec(exe -> run(`$exe -n 3 $(Base.julia_cmd()) --project .\\test2.jl`))
end
