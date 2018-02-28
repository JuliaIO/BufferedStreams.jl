__precompile__()

module BufferedStreams

export BufferedInputStream,
       BufferedOutputStream,
       peek,
       peekbytes!,
       fillbuffer!,
       isanchored,
       anchor!,
       upanchor!,
       takeanchored!

using Compat

# default buffer size is 128 KiB
const default_buffer_size = 128 * 2^10

# pretty printer of data size
function _datasize(nbytes)
    if nbytes < 1024
        return string(nbytes, " B")
    end
    k = 1
    for suffix in [" KiB", " MiB", " GiB", " TiB"]
        if nbytes < 1024^(k+1)
            return string(floor(nbytes / 1024^k, 1), suffix)
        end
        k += 1
    end
    return string(floor(nbytes / 1024^k, 1), " PiB")
end

include("bufferedinputstream.jl")
include("bufferedoutputstream.jl")
include("emptystream.jl")
include("io.jl")
include("deprecated.jl")

end # module BufferedStreams
