"""
`BufferedOutputStream{T}` provides buffered writing to a sink of type `T`.

Any type `T` wrapped in a `BufferedOutputStream` must implement:

    BufferedStreams.writebytes(sink::T, buffer::Vector{UInt8}, n::Int, eof::Bool)

This function should:

* write `n` bytes from `buffer`, starting at the first position
* `eof` is `true` when there will be no more write operations to `sink`, to
  facilitate flushing or closing the sink, etc.
* `writebytes` should return the number of bytes written. This must be
  `n` or 0. A return value of 0 indicates data should not be evicted from
  the buffer.

The buffer passed to this function never reallocated by `BufferedOutputStream`,
so it's safe to retain a reference to it to, for example, report some bytes as
written but do so lazily or asynchronously.
"""
type BufferedOutputStream{T} <: IO
    sink::T
    buffer::Vector{UInt8}

    # Position of the next unused byte in buffer
    position::Int
end

function BufferedOutputStream{T}(sink::T, buflen::Integer=default_buffer_size)
    return BufferedOutputStream{T}(sink, Array(UInt8, buflen), 1)
end

"""
Flush all accumulated data from the buffer.
"""
function flushbuffer!(stream::BufferedOutputStream, eof::Bool=false)
    buffered = stream.position - 1
    written = writebytes(stream.sink, stream.buffer, buffered, eof)
    if written != buffered
        error("BufferedOutputStream sink failed to write all data")
    end
    stream.position = 1
    return
end

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

function Base.write(stream::BufferedOutputStream, data::Vector{UInt8})
    # TODO: find a way to write large vectors directly to the sink bypassing the buffer
    append!(stream, data, 1, length(data))
end

# TODO: This is too slow. I think this pointer/pointer_to_array trick may
# allocate, so we should try to avoid it everywhere, but especially here.
"""
Write part of a byte array.
"""
function Base.append!(stream::BufferedOutputStream, data::Vector{UInt8},
                      start::Int, stop::Int)
    buffer = stream.buffer
    position = stream.position
    writelen = stop - start + 1
    buflen = length(buffer)
    while true
        if position > buflen
            stream.position = position
            flushbuffer!(stream)
            position = stream.position
            buffer = stream.buffer
            buflen = length(buffer)
        end

        num_chunk_bytes = min(stop - start + 1, buflen - position + 1)
        copy!(buffer, position, data, start, num_chunk_bytes)
        start += num_chunk_bytes
        position += num_chunk_bytes
        if start > stop
            break
        end
    end
    stream.position = position
    return writelen
end

function Base.flush(stream::BufferedOutputStream)
    flushbuffer!(stream)
    if applicable(flush, stream.sink)
        flush(stream.sink)
    end
    return stream
end

function Base.close(stream::BufferedOutputStream)
    flushbuffer!(stream, true)
    flush(stream)
    close(stream.sink)
end
