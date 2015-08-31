
"""
BufferedInputStream{T} provides buffered reading from a source of type T.

Any type T wrapped in a BufferedInputStream must implement:
    readbytes!(source::T, buffer::Vector{UInt8}, from::Int, to::Int)

This function should:
    * refill the buffer starting at `from` and not filling past `to`.
    * return the number of bytes read.

Failure to read any new data into the buffer is interpreted as eof.
"""
type BufferedInputStream{T} <: IO
    source::T
    buffer::Vector{UInt8}

    # Position of the next byte to be read in buffer.
    position::Int

    # Number of bytes available in buffer. I.e. buffer[1:available] is valid
    # data.
    available::Int

    # If positive, preserve and move buffer[anchor:available] when refilling
    # the buffer.
    anchor::Int
end


function BufferedInputStream{T}(source::T, buflen::Int=100000)
    return BufferedInputStream{T}(source, Array(UInt8, buflen), 1, 0, 0)
end


"""
Refill the buffer, optionally moving and retaining part of the data.
"""
function fillbuffer!(stream::BufferedInputStream)
    oldbuflen = buflen = length(stream.buffer)
    keeplen = 0
    if stream.anchor > 0
        keeplen = stream.available - stream.anchor + 1

        # expand the buffer if we are attempting to keep most of it
        if 2*keeplen > buflen
            buflen *= 2
            resize!(stream.buffer, buflen)
        end

        gap = stream.position - stream.anchor
        copy!(stream.buffer, 1, stream.buffer, stream.anchor, keeplen)
        stream.available = stream.available - stream.anchor + 1
        stream.anchor = 1
        stream.position = stream.anchor + gap
    else
        stream.position = 1
    end

    nb = readbytes!(stream.source, stream.buffer, keeplen + 1, buflen)
    stream.available = nb + keeplen

    return nb
end


"""
Return true if no further data is available from the stream.
"""
@inline function Base.eof(stream::BufferedInputStream)
    return stream.position > stream.available && eof(stream.source)
end


"""
Return the next byte from the input stream without advancing the position.
"""
@inline function peek(stream::BufferedInputStream)
    position = stream.position
    if position > stream.available
        if fillbuffer!(stream) < 1
            throw(EOFError())
        end
        position = stream.position
    end
    @inbounds c = stream.buffer[position]
    return c
end


"""
Read and return one byte from the input stream.
"""
@inline function Base.read(stream::BufferedInputStream, ::Type{UInt8})
    position = stream.position
    if position > stream.available
        if fillbuffer!(stream) < 1
            throw(EOFError())
        end
        position = stream.position
    end
    @inbounds c = stream.buffer[position]
    stream.position = position + 1
    return c
end


# Special purpose readuntil for plain bytes.
function Base.readuntil(stream::BufferedInputStream, delim::UInt8)
    anchor!(stream)
    while true
        p0 = pointer(stream.buffer, stream.position)
        p1 = ccall(:memchr, Ptr{UInt8}, (Ptr{UInt8}, Cint, Csize_t),
                   p0, delim, stream.available - stream.position + 1)
        if p1 != C_NULL
            stream.position += p1 - p0
            break
        else
            stream.position = stream.available + 1
            nb = fillbuffer!(stream)
            if nb == 0
                chunk = takeanchored!(stream)
                return chunk
            end
        end
    end
    chunk = stream.buffer[upanchor!(stream):stream.position]
    stream.position += 1
    return chunk
end


function Base.readbytes!(stream::BufferedInputStream,
                         buffer::AbstractArray{UInt8}, nb=length(buffer))
    oldbuflen = buflen = length(buffer)
    outpos = 1
    while !eof(stream) && outpos <= nb
        if stream.position > stream.available && fillbuffer!(stream) < 1
            break
        end

        num_chunk_bytes = min(nb - outpos + 1, stream.available - stream.position + 1)
        if outpos + num_chunk_bytes > buflen
            buflen = max(buflen + num_chunk_bytes, 2*buflen)
            resize!(buffer, buflen)
        end

        copy!(buffer, outpos, stream.buffer, stream.position, num_chunk_bytes)
        stream.position += num_chunk_bytes
        outpos += num_chunk_bytes
    end

    if buflen > oldbuflen
        resize!(buffer, outpos - 1)
    end

    return outpos - 1
end


"""
Return true if the stream is anchored.
"""
function isanchored(stream::BufferedInputStream)
    return stream.anchor != 0
end


"""
Set the buffer's anchor to its current position.
"""
function anchor!(stream::BufferedInputStream)
    stream.anchor = stream.position
end


"""
Remove and return a buffer's anchor.
"""
function upanchor!(stream::BufferedInputStream)
    anchor = stream.anchor
    stream.anchor = 0
    return anchor
end


"""
Copy and return a byte array from the anchor up to, but not including the
current position, also removing the anchor.
"""
function takeanchored!(stream::BufferedInputStream)
    if stream.position - 1 > stream.available
        throw(EOFError())
    end
    chunk = stream.buffer[stream.anchor:stream.position - 1]
    stream.anchor = 0
    return chunk
end


"""
Current position in the stream. Assumes the source has reportable position.
"""
function Base.position(stream::BufferedInputStream)
    return position(stream.source) - stream.available + stream.position - 1
end


"""
Move to the given position in the stream.

This will unset the current anchor if any.
"""
function Base.seek{T}(stream::BufferedInputStream{T}, pos::Integer)
    if applicable(seek, stream.source, pos)
        upanchor!(stream)
        source_position = position(stream.source)
        # is the new position within the buffer?
        if source_position - stream.available <= pos <= source_position
            stream.position = 1 + pos - (source_position - stream.available)
        else
            seek(stream.source, pos)
            stream.position = 1
            stream.available = 0
        end
    else
        error("Can't seek in input stream with source of type ", T)
        # TODO: Allow seeking forwards by just reading and discarding input
    end
end


