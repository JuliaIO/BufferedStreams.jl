using Documenter, BufferedStreams

makedocs(
    format = :html,
    sitename = "BufferedStreams",
    pages = [
        "Home" => "index.md",
        "Input Streams" => "inputstreams.md",
        "Output Streams" => "outputstreams.md"
    ],
    authors = "D. C. Jones, Ben J. Ward"
)

deploydocs(
    repo = "github.com/BioJulia/BufferedStreams.jl.git",
    julia = "0.6",
    osname = "linux",
    target = "build",
    deps = nothing,
    make = nothing
)
