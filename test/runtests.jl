using Test
using JobQueueMPI
using MPI
ENV["JULIA_PROJECT"] = dirname(Base.active_project())

JQM = JobQueueMPI

test_1_path = joinpath(".", "test1.jl")
test_2_path = joinpath(".", "test2.jl") 

@testset verbose = true "JobQueueMPI Tests" begin
    mpiexec(exe -> run(`$exe -n 3 $(Base.julia_cmd()) --project $(test_1_path)`))
    mpiexec(exe -> run(`$exe -n 3 $(Base.julia_cmd()) --project $(test_2_path)`))
end
