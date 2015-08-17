
module BufferedStreams

export BufferedInputStream, fillbuffer!, anchor!, upanchor!


"""
BufferedInputStream{T} performs buffered reading from a source of type T.

Any type T wrapped in a BufferedInputStream must implement:
    readbytes!(source::T, buffer::Vector{Uint8}, from::Int, to::Int)

This function should:
    * refill the buffer starting at `from` and not filling past `to`.
    * return the number of bytes read.

TODO: maybe there shoulde be a mechanism from the source to notify the caller
that it needs more space in the buffer to fill anything.

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

    # True if the source has no more available input.
    source_finished::Bool
end


function BufferedInputStream{T}(source::T, buflen::Int=8192)
    BufferedInputStream{T}(source, Array(Uint8, buflen), 1, 0, 0, false)
end


# Should we be able to call fillbuffer! when position is not at the end?

"""
Refill the buffer, optionally moving and retaining part of the data.

TODO: Define semantics carefull...

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
    stream.available = nb

    if nb == 0
        stream.source_finished = true
    end
    return nb
end


"""
Return true if no further data is available from the stream.
"""
@inline function Base.eof(stream::BufferedInputStream)
    return stream.position > stream.available && eof(stream.source)
end


"""
Read and return one byte from the input stream.
"""
@inline function Base.read{T}(stream::BufferedInputStream{T}, ::Type{UInt8})
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


include("sources.jl")


end # module BufferedStreams


