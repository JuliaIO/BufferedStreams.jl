Base.@deprecate_binding EmptyStreamSource EmptyStream
Base.@deprecate seekforward(stream::BufferedInputStream, n::Integer) skip(stream, n)

# emptystream.jl 

if VERSION < v"0.6.0-dev.1256"
    function Base.takebuf_array(stream::BufferedOutputStream{EmptyStream})
        chunk = stream.buffer[1:stream.position-1]
        stream.position = 1
        return chunk
    end
end

if v"0.5" <= VERSION < v"0.6.0-dev.1256"
    function Base.takebuf_string(stream::BufferedOutputStream{EmptyStream})
        return String(takebuf_array(stream))
    end
elseif VERSION < v"0.5"
    function Base.takebuf_string(stream::BufferedOutputStream{EmptyStream})
        chunk = takebuf_array(stream)
        return isvalid(ASCIIString, chunk) ? ASCIIString(chunk) : UTF8String(chunk)
    end
end
