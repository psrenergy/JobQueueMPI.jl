import JobQueueMPI as JQM
using Test
using MPI
using Optim

JQM.mpi_init()

N = 5
data = collect(1:N)
function g(x, i, data)
    return i * (x[i] - 2 * i)^2 + data[i]
end
x0 = zeros(N)
list_i = collect(1:N)
fake_input = Int[] # ignored

let
    is_done = false
    if JQM.is_controller_process()
        ret = optimize(x0, NelderMead()) do x
            MPI.bcast(is_done, MPI.COMM_WORLD)
            g_x = JQM.pmap((v) -> g(v[1], v[2], data), [(x, i) for i in list_i])
            return sum(g_x)
        end
        # tell workers to stop calling pmap
        is_done = true
        MPI.bcast(is_done, MPI.COMM_WORLD)
        @testset "pmap MPI Optim" begin
            @test maximum(Optim.minimizer(ret) .- collect(2:2:2N)) ≈ 0.0 atol = 1e-3
            @test Optim.minimum(ret) ≈ sum(1:N) atol = 1e-3
        end
    else
        # optimize will call pmap multiple times
        # hence, the other processes need to be continuously calling pmap
        # to work with the controller.
        # once the controller leaves the optimize function it will
        # broadcast a is_done = true, so that the workers stop the
        # infinite loop of pmaps.
        while true
            is_done = MPI.bcast(is_done, MPI.COMM_WORLD)
            if is_done
                break
            end
            JQM.pmap((v) -> g(v[1], v[2], data), fake_input)
        end
    end
end

JQM.mpi_barrier()

JQM.mpi_finalize()
