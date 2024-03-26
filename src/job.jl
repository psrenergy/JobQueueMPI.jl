abstract type AbstractJob end

mutable struct Job <: AbstractJob
    message::Any
end

mutable struct JobAnswer <: AbstractJob
    message::Any
end

mutable struct JobInterrupt <: AbstractJob
    message::Any
end

mutable struct JobTerminate <: AbstractJob
    message::Any
end

mutable struct JobRequest
    worker::Int
    request::MPI.Request
end

get_message(job::AbstractJob) = job.message

function _wait_all(job_requests::Vector{JobRequest})
    requests = [job_request.request for job_request in job_requests]
    return MPI.Waitall(requests)
end
