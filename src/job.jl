abstract type AbstractJob end

mutable struct Job <: AbstractJob
    message::Any
    f::Function
end

mutable struct JobAnswer <: AbstractJob
    message::Any
end

get_message(job::AbstractJob) = job.message
get_task(job::Job) = job.f
