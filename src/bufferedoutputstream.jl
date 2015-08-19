
"""
BufferedOutputStream{T} provides buffered writing to a sink of type T.

Any type T wrapped in a BufferedOutputStream must implement:
    writebytes(sink::T, buffer::Vector{UInt8}, n::Int, eof::Bool)

This function should:
    * write n bytes from buffer, starting at the first position
    * eof is true when there will be no more write operations to the sink, to
      facilitate flushing or closing the sink, etc.
    * `writebytes` should return the number of bytes written. This must be
      `n` or 0. A return value of 0 indicates data should not be evicted from
      the buffer.

The buffer passed to this function never reallocated by BufferedOutputStream,
so it's safe to retain a reference to it to, for example, report some bytes as
written but do so lazily or asynchronously.
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
Flush all accumulated data from the buffer.
"""
function flushbuffer!(stream::BufferedOutputStream, eof::Bool=false)
    nb = writebytes(stream.sink, stream.buffer, stream.position - 1, eof)
    if nb == stream.position - 1
        stream.position = 1
    elseif nb != 0
        error("BufferedOutputStream sink failed to write all data")
    end
    return
end


"""
Read and return one byte.
"""
@inline function Base.write(stream::BufferedOutputStream, b::UInt8)
    position = stream.position
    buffer = stream.buffer
    if position > length(buffer)
        flushbuffer!(stream)
        position = stream.position
        buffer = stream.buffer
        if position > length(buffer)
            throw(EOFError)
        end
    end
    @inbounds buffer[position] = b
    stream.position = position + 1
    return 1
end


"""
Write a byte array.
"""
function Base.write(stream::BufferedOutputStream, data::Vector{UInt8})
    # TODO: find a way to write large vectors directly to the sink bypassing the buffer

    buffer = stream.buffer
    position = stream.position
    datalen = length(data)
    buflen = length(buffer)
    written = 0
    while true
        if position > buflen
            stream.position = position
            flushbuffer!(stream)
            position = stream.position
            buffer = stream.buffer
            buflen = length(buffer)
        end

        num_chunk_bytes = min(datalen - written, buflen - position + 1)
        copy!(buffer, position, data, written + 1, num_chunk_bytes)
        written += num_chunk_bytes
        position += num_chunk_bytes
        if written >= datalen
            break
        end
    end
    stream.position = position
end


function Base.flush(stream::BufferedOutputStream)
    flushbuffer!(stream)
end


function Base.close(stream::BufferedOutputStream)
    flushbuffer!(stream, true)
end


# TODO: writing arrays
