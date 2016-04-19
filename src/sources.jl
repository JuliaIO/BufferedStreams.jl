
# Vector{UInt8} source
# --------------------


# Most sinks always write all available data, so don't need to handle the `eof`
# parameter.
function writebytes(sink, buffer::Vector{UInt8}, n::Int, eof::Bool)
    return writebytes(sink, buffer, n)
end


"""
EmptyStreamSource is a dummy source to allow BufferedInputStream to wrap an
array without additional buffering.
"""
immutable EmptyStreamSource end


function Base.position(stream::BufferedInputStream{EmptyStreamSource})
    return stream.position - 1
end


function Base.seek(stream::BufferedInputStream{EmptyStreamSource}, pos::Integer)
    upanchor!(stream)
    if 1 <= pos + 1 <= stream.available
        stream.position = pos + 1
    else
        throw(BoundsError)
    end
end


function readbytes!(::EmptyStreamSource, ::Vector{UInt8}, ::Int, ::Int)
    return 0
end

Base.eof(source::EmptyStreamSource) = true
Base.close(source::EmptyStreamSource) = nothing


function BufferedInputStream(data::Vector{UInt8})
    return BufferedInputStream{EmptyStreamSource}(EmptyStreamSource(), data, 1, length(data), 0)
end


function BufferedInputStream(data::Vector{UInt8}, len::Integer)
    return BufferedInputStream{EmptyStreamSource}(EmptyStreamSource(), data, 1, len, 0)
end


# Resize the buffer. This way we can do IOBuffer-style string-building.
function writebytes(source::EmptyStreamSource, buffer::Vector{UInt8}, n::Int, eof::Bool)
    # TODO: what happens when we try to resize mmaped data?
    if n >= length(buffer)
        resize!(buffer, max(n, max(1024, 2 * length(buffer))))
    end
    return 0
end


# Faster append for vector-backed output streams.
@inline function Base.append!(stream::BufferedOutputStream{EmptyStreamSource},
                              data::Vector{UInt8}, start::Int, stop::Int)
    n = stop - start + 1
    if stream.position + n > length(stream.buffer)
        resize!(stream.buffer, max(n, max(1024, 2 * length(stream.buffer))))
    end
    copy!(stream.buffer, stream.position, data, start, n)
    stream.position += n
end


function Base.takebuf_array(stream::BufferedOutputStream{EmptyStreamSource})
    # TODO: benchmark resizing stream.buffer, returning it, and replacing it
    # with an zero-length array, which might be fast in the common case of
    # building just one array/string.
    chunk = stream.buffer[1:stream.position-1]
    stream.position = 1
    return chunk
end


function Base.takebuf_string(stream::BufferedOutputStream{EmptyStreamSource})
    chunk = takebuf_array(stream)
    return isvalid(ASCIIString, chunk) ? ASCIIString(chunk) : UTF8String(chunk)
end


function BufferedOutputStream()
    return BufferedOutputStream{EmptyStreamSource}(EmptyStreamSource(), Array(UInt8, 1024), 1)
end


function Base.empty!(stream::BufferedOutputStream{EmptyStreamSource})
    return stream.position = 1
end


function Base.isempty(stream::BufferedOutputStream{EmptyStreamSource})
    return stream.position == 1
end


function Base.length(stream::BufferedOutputStream{EmptyStreamSource})
    return stream.position - 1
end


function Base.(:(==))(a::BufferedOutputStream{EmptyStreamSource},
                      b::BufferedOutputStream{EmptyStreamSource})
    if a.position == b.position
        return ccall(:memcmp, Cint, (Ptr{Void}, Ptr{Void}, Csize_t),
                     a.buffer, b.buffer, a.position - 1) == 0
    else
        return false
    end
end


# IO source
# ---------

#function Base.readbytes!(source::IO, buffer::Vector{UInt8}, from::Int, to::Int)
    #i = from
    #while i <= to && !eof(source)
        #@inbounds buffer[i] = read(source, Uint8)
        #i += 1
    #end
    #return i - from
#end


#function writebytes(source::IO, buffer::Vector{UInt8}, n::Int)
    #for i in 1:n
        #write(source, buffer[i])
    #end
    #return n
#end


# Source and sink interface for generic IO types
function readbytes!(source::IO, buffer::AbstractArray{UInt8}, from::Int, to::Int)
    return Base.readbytes!(
        source,
        pointer_to_array(pointer(buffer, from), (to - from + 1,)),
        to - from + 1)
end


function writebytes(source::IO, buffer::AbstractArray{UInt8}, n::Int)
    return write(source, pointer_to_array(pointer(buffer), (n,)))
end



# IOStream source
# ---------------

function readbytes!(source::IOStream, buffer::AbstractArray{UInt8}, from::Int, to::Int)
    return ccall(:ios_readall, UInt, (Ptr{Void}, Ptr{Void}, UInt), source.ios,
                 pointer(buffer, from), to - from + 1)
end


# TODO: using ios_write, but look into _os_write_all
#function Base.write(source::IOStream, buffer::Vector{UInt8}, n::Int)

#end




