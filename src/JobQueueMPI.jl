module JobQueueMPI

using MPI

export Controller, JobQueueMPI, Job, JobAnswer, Worker, TerminationMessage

include("mpi_utils.jl")
include("job.jl")
include("worker.jl")
include("controller.jl")

end # module JobQueueMPI
