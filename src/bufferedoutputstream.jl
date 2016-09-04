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

    # Position of the next unused byte in buffer;
    # `position ≤ 0` indicates that the stream is closed.
    position::Int
end

function BufferedOutputStream{T}(sink::T, bufsize::Integer=default_buffer_size)
    if bufsize ≤ 0
        throw(ArgumentError("buffer size must be positive"))
    end
    return BufferedOutputStream{T}(sink, Vector{UInt8}(bufsize), 1)
end

function Base.show{T}(io::IO, stream::BufferedOutputStream{T})
    bufsize = length(stream.buffer)
    filled = stream.position
    if isopen(stream)
        print(io,
            summary(stream), "(<",
            _datasize(bufsize), " buffer, ",
            round(Int, filled / bufsize * 100), "% filled>)")
    else
        print(io, summary(stream), "(<closed>)")
    end
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

function checkopen(stream::BufferedOutputStream)
    if !isopen(stream)
        error("buffered output stream is already closed")
    end
end

@inline function Base.write(stream::BufferedOutputStream, b::UInt8)
    checkopen(stream)
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
    checkopen(stream)
    # TODO: find a way to write large vectors directly to the sink bypassing the buffer
    #append!(stream, data, 1, length(data))
    n_avail = endof(stream.buffer) - stream.position + 1
    n = min(length(data), n_avail)
    copy!(stream.buffer, stream.position, data, 1, n)
    stream.position += n
    written = n
    while written < length(data)
        flushbuffer!(stream)
        n_avail = endof(stream.buffer) - stream.position + 1
        @assert n_avail > 0
        n = min(endof(data) - written, n_avail)
        copy!(stream.buffer, stream.position, data, written + 1, n)
        stream.position += n
        written += n
    end
    return written
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
    return
end

function Base.isopen(stream::BufferedOutputStream)
    return stream.position > 0
end

function Base.close(stream::BufferedOutputStream)
    if !isopen(stream)
        return
    end
    flush(stream)
    if applicable(close, stream.sink)
        close(stream.sink)
    end
    empty!(stream.buffer)
    stream.position = 0
    return
end

function Base.eof(stream::BufferedOutputStream)
    return true
end

function Base.pointer(stream::BufferedOutputStream, index::Integer=1)
    return pointer(stream.buffer, stream.position + index - 1)
end

function available_bytes(stream::BufferedOutputStream)
    return max(endof(stream.buffer) - stream.position + 1, 0)
end
