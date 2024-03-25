abstract type AbstractJob end

mutable struct Job <: AbstractJob
    message::Any
    f::Function
end

mutable struct JobAnswer <: AbstractJob
    message::Any
end

mutable struct JobRequest
    worker::Int
    request::MPI.Request
end

get_message(job::AbstractJob) = job.message
get_task(job::Job) = job.f

is_request_complete(job_request::JobRequest) = MPI.test(job_request.request)

function _wait_all(job_requests::Vector{JobRequest})
    requests = [job_request.request for job_request in job_requests]
    return MPI.Waitall(requests)
end
