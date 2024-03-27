abstract type AbstractJob end

@kwdef mutable struct Job{T} <: AbstractJob
    id::Int = 0
    message::T
end

 mutable struct JobAnswer{T} <: AbstractJob
    job_id::Int
    message::T
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
