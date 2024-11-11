using Documenter

using JobQueueMPI
const JQM = JobQueueMPI

makedocs(;
    modules = [JobQueueMPI],
    doctest = true,
    clean = true,
    format = Documenter.HTML(; mathengine = Documenter.MathJax2()),
    sitename = "JobQueueMPI.jl",
    authors = "psrenergy",
    pages = [
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo = "github.com/psrenergy/JobQueueMPI.jl.git",
    push_preview = true,
)
