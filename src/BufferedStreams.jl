
module BufferedStreams

export BufferedInputStream,
       EmptyStreamSource,
       fillbuffer!,
       anchor!,
       upanchor!,
       takeanchored!


include("bufferedinputstream.jl")
include("sources.jl")


end # module BufferedStreams


