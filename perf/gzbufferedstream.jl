using GZip

type GZBufferedStream <: IO
    io::GZipStream
    buf::Vector{UInt8}
    len::Int
    ptr::Int

    function GZBufferedStream(io::GZipStream)
        buf = Array(UInt8, io.buf_size)

        len = ccall((:gzread, GZip._zlib), Int32,
            (Ptr{Void}, Ptr{Void}, UInt32), io.gz_file, buf, io.buf_size)

        new(io, buf, len, 1)
    end
end

Base.close(io::GZBufferedStream) = close(io.io)

@inline function Base.read(io::GZBufferedStream, ::Type{UInt8})
    c = io.buf[io.ptr]
    io.ptr += 1

    if io.ptr == io.len+1 #No more data
        io.len = ccall((:gzread, GZip._zlib), Int32,
            (Ptr{Void}, Ptr{Void}, UInt32), io.io.gz_file, io.buf, io.io.buf_size)
        io.ptr = 1
    end
    c
end

@inline Base.eof(io::GZBufferedStream) = io.len == 0

#function bench()
    #io = GZBufferedStream(GZip.open("random.gz", "rb"))

    #thischar = 0x00
    #n = 0
    #while !eof(io)
        #thischar = read(io, UInt8)
        #n += 1
    #end
    #close(io)

    #println(n)
    #thischar
#end


#bench()

##random contains 10^8 rand(UInt8)s
#@time run(`gunzip -k -f random.gz`) #255 ms
#@time bench() #168 ms


