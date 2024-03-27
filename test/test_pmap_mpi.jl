using JobQueueMPI
using Test
JQM = JobQueueMPI

JQM.mpi_init()

function sum_100(value)
    return value + 100
end

function get_divisors(n)
    divisors = Int[]
    for i in 1:n
        if n % i == 0
            push!(divisors, i)
        end
    end
    return divisors
end

sum_100_answer = JQM.pmap(sum_100, collect(1:10))
divisors_answer = JQM.pmap(get_divisors, collect(1:10))

if JQM.is_controller_process()
    @testset "pmap MPI" begin
        @test sum_100_answer == [101, 102, 103, 104, 105, 106, 107, 108, 109, 110]
        @test divisors_answer ==
                [[1], [1, 2], [1, 3], [1, 2, 4], [1, 5], [1, 2, 3, 6], [1, 7], [1, 2, 4, 8], [1, 3, 9], [1, 2, 5, 10]]
    end
end

JQM.mpi_finalize()
