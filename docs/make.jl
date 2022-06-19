using Documenter, BufferedStreams

makedocs(
    format = Documenter.HTML(
        prettyurls = !("local" in ARGS),
        canonical = "https://juliaio.net/BufferedStreams.jl/stable/",
    ),
    sitename = "BufferedStreams",
    pages = [
        "Home" => "index.md",
        "Input Streams" => "inputstreams.md",
        "Output Streams" => "outputstreams.md"
    ],
    authors = "D. C. Jones, Ben J. Ward"
)

deploydocs(
    repo = "github.com/JuliaIO/BufferedStreams.jl.git",
    target = "build",
)
