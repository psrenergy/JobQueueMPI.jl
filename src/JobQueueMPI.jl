module JobQueueMPI

using MPI

include("mpi_utils.jl")
include("worker.jl")
include("controller.jl")

end # module JobQueueMPI
