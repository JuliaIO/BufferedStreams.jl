"""
`BufferedInputStream{T}` provides buffered reading from a source of type `T`.

Any type `T` wrapped in a `BufferedInputStream` must implement:

    BufferedStreams.readbytes!(source::T, buffer::Vector{UInt8}, from::Int, to::Int)

This function should:

* refill `buffer` starting at `from` and not filling past `to`.
* return the number of bytes read.

Failure to read any new data into the buffer is interpreted as eof.
"""
mutable struct BufferedInputStream{T} <: IO
    source::T
    buffer::Vector{UInt8}

    # Position of the next byte to be read in buffer;
    # `position ≤ 0` indicates that the stream is closed.
    position::Int

    # Number of bytes available in buffer.
    # I.e. buffer[1:available] is valid data.
    available::Int

    # If positive, preserve and move buffer[anchor:available]
    # when refilling the buffer.
    anchor::Int

    # If `true`, buffered data `buffer[anchor:available]` is not shifted.
    immobilized::Bool
end

function BufferedInputStream(source::T, bufsize::Integer = default_buffer_size) where T
    if bufsize ≤ 0
        throw(ArgumentError("buffer size must be positive"))
    end
    return BufferedInputStream{T}(source, Vector{UInt8}(undef, bufsize), 1, 0, 0, false)
end

function Base.show(io::IO, stream::BufferedInputStream{T}) where T
    bufsize = length(stream.buffer)
    filled = stream.available - stream.position + 1
    if isopen(stream)
        print(io,
            summary(stream), "(<",
            _datasize(bufsize), " buffer, ",
            round(Int, filled / bufsize * 100), "% filled",
            stream.immobilized ? ", data immobilized" : "", ">)")
    else
        print(io, summary(stream), "(<closed>)")
    end
end

"""
Refill the buffer, optionally moving and retaining part of the data,
ensuring buffer space to read at least `minalloc` bytes.
"""
function fillbuffer!(stream::BufferedInputStream, minalloc::Int = 1)
    if eof(stream.source)
        return 0
    end

    shiftdata!(stream)
    margin = length(stream.buffer) - stream.available
    if margin < minalloc
        resize!(stream.buffer, length(stream.buffer) * 2 + minalloc-1)
    end

    nbytes = readbytes!(
        stream.source,
        stream.buffer,
        stream.available + 1,
        length(stream.buffer))
    stream.available += nbytes
    return nbytes
end

# Shift data to be kept.
function shiftdata!(stream::BufferedInputStream)
    if stream.immobilized
        return 0
    else
        if stream.anchor > 0 && stream.available - stream.anchor + 1 > 0
            shift = stream.anchor - 1
            n = stream.available - shift
            copyto!(stream.buffer, 1, stream.buffer, stream.anchor, n)
            stream.anchor -= shift
        elseif stream.available - stream.position + 1 > 0
            shift = stream.position - 1
            n = stream.available - shift
            copyto!(stream.buffer, 1, stream.buffer, stream.position, n)
        else
            # no data to be kept
            @assert stream.position > stream.available
            shift = stream.available
        end
        stream.position -= shift
        stream.available -= shift
        return shift
    end
end

@inline function Base.eof(stream::BufferedInputStream)
    if stream.position > stream.available
        return fillbuffer!(stream) == 0
    else
        return false
    end
end

@inline function Base.bytesavailable(stream::BufferedInputStream)
    if eof(stream)
        return 0
    else
        return stream.available - stream.position + 1
    end
end

@inline function Base.readavailable(stream::BufferedInputStream)
    read(stream, bytesavailable(stream))
end

@inline function Base.skip(stream::BufferedInputStream, n_::Integer)
    n0 = n = convert(Int, n_)
    if n < 0
        throw(ArgumentError("n must be non-negative in skip(::BufferedInputStream, n)"))
    end

    while stream.position + n > stream.available + 1
        n -= stream.available - stream.position + 1
        stream.position = stream.available + 1
        if fillbuffer!(stream) < 1
            throw(EOFError())
        end
    end
    stream.position += n
    return n0
end

@inline function checkopen(stream::BufferedInputStream)
    if !isopen(stream)
        error("buffered input stream is already closed")
    end
end

"""
Return the next byte from the input stream without advancing the position.
"""
@inline function Base.peek(stream::BufferedInputStream)
    checkopen(stream)
    if stream.position > stream.available
        if fillbuffer!(stream) < 1
            throw(EOFError())
        end
    end
    @inbounds c = stream.buffer[stream.position]
    return c
end

"""
Fills `buffer` with bytes from `stream`'s buffer without advancing the
position.

Unless the buffer is empty, we do not re-fill it. Therefore the number of bytes
read is limited to the minimum of `nb` and the remaining bytes in the buffer.
"""
function peekbytes!(stream::BufferedInputStream,
                    buffer::AbstractArray{UInt8},
                    nb=length(buffer))
    checkopen(stream)
    if stream.position > stream.available
        if fillbuffer!(stream) < 1
            throw(EOFError())
        end
    end
    nb = min(nb, stream.available - stream.position + 1)
    copyto!(buffer, 1, stream.buffer, stream.position, nb)
    return nb
end

@inline function Base.read(stream::BufferedInputStream, ::Type{UInt8})
    checkopen(stream)
    if stream.position > stream.available
        if fillbuffer!(stream) < 1
            throw(EOFError())
        end
    end
    @inbounds c = stream.buffer[stream.position]
    stream.position += 1
    return c
end

# fast multi-byte data readers
for T in [Int16, UInt16, Int32, UInt32, Int64, UInt64, Int128, UInt128, Float16, Float32, Float64]
    @eval begin
        @inline function Base.read(stream::BufferedInputStream, ::Type{$(T)})
            checkopen(stream)
            if !ensurebuffered!(stream, $(sizeof(T)))
                throw(EOFError())
            end
            ptr::Ptr{$(T)} = pointer(stream)
            ret = unsafe_load(ptr)
            stream.position += $(sizeof(T))
            return ret
        end
    end
end

# fast char reader, split into lower-level routine for read(s, Char) + peek(s, Char) etc.
function _readchar(stream::BufferedInputStream)
    ensurebuffered!(stream, 4)
    p, avail = stream.position, stream.available
    p > avail && throw(EOFError())

    # code adapted from Base.read(io::IO, ::Type{Char}):
    @inbounds b0 = stream.buffer[p]
    p += 1
    l = 0x08 * (0x04 - (leading_ones(b0) % UInt8))
    c = UInt32(b0) << 24
    if l < 0x18
        s = 16
        while s ≥ l && p ≤ avail
            @inbounds b = stream.buffer[p]
            b & 0xc0 == 0x80 || break
            p += 1
            c |= UInt32(b) << s
            s -= 8
        end
    end
    return reinterpret(Char, c), p
end
function Base.read(stream::BufferedInputStream, ::Type{Char})
    checkopen(stream)
    c, stream.position = _readchar(stream)
    return c
end
function Base.peek(stream::BufferedInputStream, ::Type{Char})
    checkopen(stream)
    c, _ = _readchar(stream)
    return c
end
function Base.skipchars(predicate, stream::BufferedInputStream; linecomment=nothing)
    checkopen(stream)
    while !eof(stream)
        c, p = _readchar(stream)
        if c === linecomment
            stream.position = p # next Char
            while ensurebuffered!(stream, 1)
                @views lf = findnext(==(0x0a), stream.buffer[1:stream.available], stream.position)
                if isnothing(lf)
                    stream.position = stream.available + 1 # fill buffer again
                else
                    stream.position = lf + 1 # skip to next line
                    break
                end
            end
        elseif predicate(c)
            stream.position = p # skip to next Char
        else
            break
        end
    end
    return stream
end

if isdefined(Base, :unsafe_read)
    function Base.unsafe_read(stream::BufferedInputStream, ptr::Ptr{UInt8}, nb::UInt)
        p = ptr
        p_end = ptr + nb
        while p < p_end
            if ensurebuffered!(stream, 1)
                n = min(p_end - p, available_bytes(stream))
                ccall(:memcpy, Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}, Csize_t), p, pointer(stream), n)
                p += n
                stream.position += n
            else
                throw(EOFError())
            end
        end
        return nothing
    end
end

# Special purpose readuntil for plain bytes.
function Base.readuntil(stream::BufferedInputStream, delim::UInt8)
    checkopen(stream)
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

function readbytes!(stream::BufferedInputStream,
                    buffer::AbstractArray{UInt8},
                    nb=length(buffer))
    return readbytes!(stream, buffer, 1, nb)
end

function readbytes!(stream::BufferedInputStream,
                    buffer::AbstractArray{UInt8},
                    from::Int, to::Int)
    p = from
    while !eof(stream) && p ≤ to
        @assert ensurebuffered!(stream, 1)
        n = min(to - p + 1, stream.available - stream.position + 1)
        copyto!(buffer, p, stream.buffer, stream.position, n)
        p += n
        stream.position += n
    end
    return p - from
end

function Base.ismarked(stream::BufferedInputStream)
    return stream.anchor > 0
end

function Base.mark(stream::BufferedInputStream)
    stream.anchor = stream.position
    return stream.anchor
end

function Base.unmark(stream::BufferedInputStream)
    if !ismarked(stream)
        return false
    end
    stream.anchor = 0
    return true
end

function Base.reset(stream::BufferedInputStream)
    if !ismarked(stream)
        error("buffered stream is not marked")
    end
    anchor = stream.anchor
    stream.position = anchor
    unmark(stream)
    return anchor
end

"""
Return true if the stream is anchored.
"""
function isanchored(stream::BufferedInputStream)
    return stream.anchor > 0
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
    upanchor!(stream)
    return chunk
end

function Base.position(stream::BufferedInputStream)
    return position(stream.source) - stream.available + stream.position - 1
end

function Base.seek(stream::BufferedInputStream{T}, pos::Integer) where T
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
        throw(ArgumentError(
            string("Can't seek in input stream with source of type ", T)))
        # TODO: Allow seeking forwards by just reading and discarding input
    end
    return stream
end

function Base.isopen(stream::BufferedInputStream)
    return stream.position > 0
end

function Base.close(stream::BufferedInputStream)
    if !isopen(stream)
        return
    end
    if applicable(close, stream.source)
        close(stream.source)
    end
    stream.position = 0
    empty!(stream.buffer)
    return
end

function Base.pointer(stream::BufferedInputStream, index::Integer=1)
    return pointer(stream.buffer, stream.position + index - 1)
end

@inline function available_bytes(stream::BufferedInputStream)
    return stream.available - stream.position + 1
end

@inline function ensurebuffered!(stream::BufferedInputStream, nb::Integer)
    if available_bytes(stream) < nb
        fillbuffer!(stream, nb)
        if available_bytes(stream) < nb
            return false
        end
    end
    return true
end
