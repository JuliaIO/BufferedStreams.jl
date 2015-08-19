
"""
BufferedOutputStream{T} provides buffered writing to a sink of type T.

Any type T wrapped in a BufferedOutputStream must implement:
    writebytes(sink::T, buffer::Vector{UInt8}, n::Int, eof::Bool)

This function should:
    * write data from buffer, starting at 1, and not exceeding `to` bytes.
    * if eof is true, all data must be written
    * return the number of bytes written

buffer is never resized, so it's safe to retain a reference to it.

TODO: This is not strictly true. Clarify
Failure to write any data is treated as an error.
"""
type BufferedOutputStream{T} <: IO
    sink::T
    buffer::Vector{UInt8}

    # Position of the next unused byte in buffer
    position::Int
end


function BufferedOutputStream{T}(sink::T, buflen::Int=100000)
    return BufferedOutputStream{T}(sink, Array(UInt8, buflen), 1)
end


"""
Write out as much of the buffer as we can.
"""
function flushbuffer!(stream::BufferedOutputStream, eof::Bool=false)
    nb = writebytes(stream.sink, stream.buffer, stream.position - 1, eof)
    if nb == stream.position - 1
        stream.position = 1
    end
    return nb
end


"""
Read and return one byte.
"""
@inline function Base.write(stream::BufferedOutputStream, c::UInt8)
    position = stream.position
    buffer = stream.buffer
    if position > length(buffer)
        nb = flushbuffer!(stream)
        position = stream.position
        buffer = stream.buffer
        if position > length(buffer)
            @show position
            @show length(buffer)
            @show nb
            throw(EOFError)
        end
    end
    @inbounds buffer[position] = c
    stream.position = position + 1
    return 1
end


function Base.close(stream::BufferedOutputStream)
    flushbuffer!(stream, true)
    if stream.position > 1
        error("BufferedOutputStream sink failed to write all data")
    end
end


# TODO: writing arrays
