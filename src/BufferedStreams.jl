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

# default buffer size is 128 KiB
const default_buffer_size = 128 * 2^10

include("bufferedinputstream.jl")
include("bufferedoutputstream.jl")
include("sources.jl")
include("emptystream.jl")

end # module BufferedStreams
