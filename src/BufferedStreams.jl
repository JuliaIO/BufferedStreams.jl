__precompile__()

module BufferedStreams

export BufferedInputStream,
       BufferedOutputStream,
       EmptyStreamSource,
       peek,
       peekbytes!,
       seekforward,
       fillbuffer!,
       isanchored,
       anchor!,
       upanchor!,
       takeanchored!

include("bufferedinputstream.jl")
include("bufferedoutputstream.jl")
include("sources.jl")

end # module BufferedStreams
