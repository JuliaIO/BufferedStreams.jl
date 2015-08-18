
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


# TODO: We need some way to detect EOF without having to read anything.
#
# I wonder if I can reconfigure things to not insist on a `eof` function.
#
# Like: assume eof if we read zero bytes. Try to fill the buffer on
# initialization, that way the source_finished flag is always up to date.
#
# It won't really be up to date unless we always call fillbuffer! when there is
# something still in the buffer to get.
#
# Maybe that's a good idea. Get the byte, then check if we need to fill the
# buffer.

function Base.readbytes!(source::Base.FS.File, buffer::Vector{UInt8}, from::Int, to::Int)
    nb = ccall(:jl_fs_read, Cint, (Cint, Ptr{Cchar}, Csize_t),
                 source.handle, pointer(buffer, from), to - from + 1)
    return nb
end


# TODO: how....?
function Base.eof(source::Base.FS.File)
    return false
end
