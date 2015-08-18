

# Useful for wrapping an array or mmaped data in a BufferedInputStream
# TODO: I should probably introduce some special type instead of using Nothing

function Base.readbytes!(source::Nothing, buffer::Vector{UInt8}, from::Int, to::Int)
    return 0
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

function Base.readbytes!(source::Base.FS.File, buffer::Vector{UInt8}, from::Int, to::Int)
    nb = ccall(:jl_fs_read, Cint, (Cint, Ptr{Cchar}, Csize_t),
                 source.handle, pointer(buffer, from), to - from + 1)
    return nb
end


# TODO: how....?
function Base.eof(source::Base.FS.File)
    return false
end
