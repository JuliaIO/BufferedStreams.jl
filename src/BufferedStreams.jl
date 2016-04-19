__precompile__()

module BufferedStreams

export BufferedInputStream,
       BufferedOutputStream,
       peek,
       peekbytes!,
       seekforward,
       fillbuffer!,
       isanchored,
       anchor!,
       upanchor!,
       takeanchored!

# these exported names are deprecated; will be removed
export EmptyStreamSource

include("bufferedinputstream.jl")
include("bufferedoutputstream.jl")
include("sources.jl")
include("emptystream.jl")

end # module BufferedStreams
