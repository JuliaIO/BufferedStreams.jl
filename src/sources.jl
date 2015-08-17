

# Useful for wrapping an array or mmaped data in a BufferedInputStream
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


