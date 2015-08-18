
"""
EmptyStreamSource is a dummy source to allow BufferedInputStream to wrap an
array without additional buffering.
"""
immutable EmptyStreamSource end

function Base.readbytes!(source::EmptyStreamSource, buffer::Vector{UInt8}, from::Int, to::Int)
    return 0
end


function Base.eof(source::EmptyStreamSource)
    return true
end


function BufferedInputStream(data::Vector{UInt8})
    return BufferedInputStream{EmptyStreamSource}(EmptyStreamSource(), data, 1, length(data), 0, true)
end


function Base.readbytes!(source::IO, buffer::Vector{UInt8}, from::Int, to::Int)
    i = from
    while i <= to && !eof(source)
        @inbounds buffer[i] = read(source, Uint8)
        i += 1
    end
    return i - from
end


function Base.readbytes!(source::IOStream, buffer::Vector{UInt8}, from::Int, to::Int)
    return ccall(:ios_readall, Uint, (Ptr{Void}, Ptr{Void}, Uint), source.ios,
                 pointer(buffer, from), to - from + 1)
end

