using BufferedStreams
using Test, Random

Random.seed!(314159)

struct InfiniteStream <: IO
    byte::UInt8
end

function Base.eof(stream::InfiniteStream)
    return false
end

function Base.read(stream::InfiniteStream, ::Type{UInt8})
    return stream.byte
end

if isdefined(Base, :unsafe_read)
    function Base.unsafe_read(stream::InfiniteStream, pointer::Ptr{UInt8}, n::UInt)
        ccall(:memset, Cvoid, (Ptr{Cvoid}, Cint, Csize_t), pointer, stream.byte, n)
        return nothing
    end
end


# A few things that might not be obvious:
#   * In a few places we wrap an array in an IOBuffer before wrapping it in a
#     BufferedInputStream. This is to force the BufferedInputStream to read
#     incrementally to expose possible bugs in buffer refilling logic.
#   * Similar, we manually set the buffer size to be smaller than the default to
#     force more buffer refills.

# Uncommenting top-level testset makes the tests take ~100x longer
# @testset "BufferedInputStream" begin
    @testset "BufferedInputStream: read" begin
        data = rand(UInt8, 1000000)
        stream = BufferedInputStream(IOBuffer(data), 1024)
        read_data = UInt8[]
        while !eof(stream)
            push!(read_data, read(stream, UInt8))
        end
        @test data == read_data
        @test data == read(BufferedInputStream(IOBuffer(data), 1024))

        halfn = div(length(data), 2)
        @test data[1:halfn] == read(BufferedInputStream(IOBuffer(data), 1024), halfn)

        # read multi-byte data
        buffer = IOBuffer()
        write(buffer, UInt8(1))
        write(buffer, UInt16(2))
        write(buffer, UInt32(3))
        write(buffer, UInt64(4))
        write(buffer, UInt128(5))
        write(buffer, Float16(6))
        write(buffer, Float32(7))
        write(buffer, Float64(8))
        seekstart(buffer)
        stream = BufferedInputStream(buffer)
        @test read(stream, UInt8) === UInt8(1)
        @test read(stream, UInt16) === UInt16(2)
        @test read(stream, UInt32) === UInt32(3)
        @test read(stream, UInt64) === UInt64(4)
        @test read(stream, UInt128) === UInt128(5)
        @test read(stream, Float16) === Float16(6)
        @test read(stream, Float32) === Float32(7)
        @test read(stream, Float64) === Float64(8)

        # EOFError
        stream = BufferedInputStream(IOBuffer())
        @test_throws EOFError read(stream, UInt8)
        @test_throws EOFError read(stream, UInt16)
        @test_throws EOFError read(stream, UInt32)
        @test_throws EOFError read(stream, UInt64)
        @test_throws EOFError read(stream, UInt128)
        @test_throws EOFError read(stream, Float16)
        @test_throws EOFError read(stream, Float32)
        @test_throws EOFError read(stream, Float64)
    end

    if isdefined(Base, :unsafe_read)
        @testset "BufferedInputStream: unsafe_read" begin
            stream = BufferedInputStream(IOBuffer("abcdefg"), 3)
            data = Vector{UInt8}(undef, 7)
            unsafe_read(stream, pointer(data, 1), 1)
            @test data[1] == UInt8('a')
            unsafe_read(stream, pointer(data, 2), 2)
            unsafe_read(stream, pointer(data, 4), 4)
            @test data == b"abcdefg"
            @test_throws EOFError unsafe_read(stream, pointer(data), 1)
        end
    end

    @testset "BufferedInputStream: peek" begin
        stream = BufferedInputStream(IOBuffer([0x01, 0x02]))
        @test peek(stream) === 0x01
        @test peek(stream) === 0x01
        read(stream, UInt8)
        @test peek(stream) === 0x02
        @test peek(stream) === 0x02
    end

    @testset "BufferedInputStream: bytesavailable" begin
        stream = BufferedInputStream(IOBuffer([0x01, 0x02]))
        @test bytesavailable(stream) == 2
        read(stream, 1)
        @test bytesavailable(stream) == 1
        read(stream, 1)
        @test bytesavailable(stream) == 0
    end

    @testset "BufferedInputStream: peekbytes!" begin
        data = rand(UInt8, 1000000)
        stream = BufferedInputStream(IOBuffer(data), 1024)

        read_data = Array{UInt8}(undef, 1000)
        @test peekbytes!(stream, read_data, 1000) == 1000
        @test data[1:1000] == read_data
        # Check that we read the bytes we just peeked, i.e. that the position
        # wasn't advanced on peekbytes!()
        readbytes!(stream, read_data, 1000)
        @test data[1:1000] == read_data
        # Check that we now peek the next 24 bytes, as we don't go past the end
        # of the buffer
        @test peekbytes!(stream, read_data, 1000) == 24
        @test data[1001:1024] == read_data[1:24]

        # Reset the data
        data = rand(UInt8, 1000000)
        stream = BufferedInputStream(IOBuffer(data), 1024)

        read_data = Array{UInt8}(undef, 2000)
        @test peekbytes!(stream, read_data, 2000) == 1024
        # Note that we truncate at buffer size, as
        @test data[1:1024] == read_data[1:1024]

        # Check that we only read up to the buffer size
        read_data = Array{UInt8}(undef, 5)
        @test peekbytes!(stream, read_data) == 5
        @test data[1:5] == read_data

        close(stream)
        @test_throws Exception peekbytes!(stream, read_data)
    end

    @testset "BufferedInputStream: readbytes!" begin
        stream = BufferedInputStream(IOBuffer([0x01:0xff;]), 4)
        @test !eof(stream)
        out = zeros(UInt8, 2)
        @test BufferedStreams.readbytes!(stream, out) === 2
        @test out == [0x01, 0x02]
        out = zeros(UInt8, 3)
        @test BufferedStreams.readbytes!(stream, out) === 3
        @test out == [0x03, 0x04, 0x05]
        out = zeros(UInt8, 5)
        @test BufferedStreams.readbytes!(stream, out) === 5
        @test out == [0x06, 0x07, 0x08, 0x09, 0x0a]
        @test !eof(stream)
        @test read(stream) == [0x0b:0xff;]
        @test eof(stream)
    end

    @testset "BufferedInputStream: readuntil" begin
        data = rand(UInt8, 1000000)
        stream = BufferedInputStream(IOBuffer(data), 1024)

        true_num_zeros = 0
        zero_positions = Int[]
        for (i, b) in enumerate(data)
            if b == 0x00
                push!(zero_positions, i)
                true_num_zeros += 1
            end
        end

        num_zeros = 0
        chunk_results = Bool[]
        while true
            # are we extracting the right chunk?
            chunk = readuntil(stream, 0x00)
            first = num_zeros == 0 ? 1 : zero_positions[num_zeros]+1
            last = num_zeros < length(zero_positions) ?  zero_positions[num_zeros+1] : length(data)
            true_chunk = data[first:last]
            push!(chunk_results, true_chunk == chunk)

            if !eof(stream)
                num_zeros += 1
            else
                break
            end
        end

        @test all(chunk_results)
        @test num_zeros == true_num_zeros
    end

    @testset "BufferedInputStream: arrays" begin
        data = rand(UInt8, 1000000)
        stream = BufferedInputStream(data)
        read_data = UInt8[]
        while !eof(stream)
            push!(read_data, read(stream, UInt8))
        end
        @test data == read_data
        @test data == read(BufferedInputStream(data))
    end

    @testset "BufferedInputStream: marks" begin
        # very small buffer
        stream = BufferedInputStream(IOBuffer([0x01:0xff;]), 2)
        @test !ismarked(stream)
        mark(stream)
        @test ismarked(stream)
        a = read(stream, UInt8)
        b = read(stream, UInt8)
        c = read(stream, UInt8)
        reset(stream)
        @test !ismarked(stream)
        a′ = read(stream, UInt8)
        b′ = read(stream, UInt8)
        c′ = read(stream, UInt8)
        @test (a, b, c) == (a′, b′, c′) == (0x01, 0x02, 0x03)
        mark(stream)
        @test unmark(stream)
        @test !unmark(stream)
        @test_throws ErrorException reset(stream)
    end

    @testset "BufferedInputStream: anchors" begin
        data = rand(UInt8, 100000)

        function random_range(n)
            a = rand(1:n)
            b = rand(a:n)
            return a:b
        end

        # test that anchors work correctly by extracting random intervals from a
        # buffered stream.
        function test_anchor()
            r = random_range(length(data))
            i = 1
            stream = BufferedInputStream(IOBuffer(data), 1024)
            while !eof(stream)
                if i == r.start
                    anchor!(stream)
                end
                if i == r.stop + 1
                    return takeanchored!(stream) == data[r]
                end
                read(stream, UInt8)
                i += 1
            end
            if i == r.stop + 1
                return takeanchored!(stream) == data[r]
            end
            error("nothing extracted (range: $r)")
        end

        @test all(Bool[test_anchor() for _ in 1:100])

        # issue #78
        let io = BufferedInputStream(IOBuffer("α∆"), 1)
            @test read(io, Char) == 'α'
            mark(io)
            @test [read(io, UInt8) for _=1:3] == [0xe2, 0x88, 0x86]
            reset(io)
            @test read(io, Char) == '∆'
        end
    end

    @testset "BufferedInputStream: seek" begin
        n = 100000
        data = rand(UInt8, n)
        positions = rand(0:n-1, 1000)

        function test_seek(stream, p)
            seek(stream, p)
            return position(stream) == p && read(stream, UInt8) == data[p + 1]
        end

        stream = BufferedInputStream(data)
        @test all(Bool[test_seek(stream, p) for p in positions])

        stream = BufferedInputStream(IOBuffer(data), 1024)
        @test all(Bool[test_seek(stream, p) for p in positions])
        @test seekstart(stream) === stream
    end

    @testset "BufferedInputStream: skip" begin
        n = 100000
        data = rand(UInt8, n)
        positions = rand(0:n-1, 1000)
        sort!(positions)

        last = 1
        offsets = Int[]
        for p in positions
            push!(offsets, p - last)
            last = p
        end

        function test_skip(stream, p, offset)
            skip(stream, offset)
            peek(stream) == data[p]
        end

        stream = BufferedInputStream(IOBuffer(data), 1024)
        @test_throws Exception skip(stream, n + 1)
        @test_throws Exception skip(stream, -1)

        stream = BufferedInputStream(IOBuffer(data), 1024)
        @test all(Bool[test_skip(stream, p, offset)
                       for (p, offset) in zip(positions, offsets)])
    end

    @testset "BufferedInputStream: close" begin
        iobuffer = IOBuffer([0x00, 0x01])
        stream = BufferedInputStream(iobuffer)
        @test isopen(stream)
        @test isopen(iobuffer)
        read(stream, UInt8)
        @test close(stream) === nothing
        @test !isopen(stream)
        @test !isopen(iobuffer)
        @test_throws Exception read(stream, UInt8)
        @test close(stream) === nothing
    end

    @testset "BufferedInputStream: iostream" begin
        mktemp() do path, input
            write(input, [0x01, 0x02, 0x03, 0x04, 0x05])
            flush(input)
            seekstart(input)

            stream = BufferedInputStream(input, 2)
            @test !eof(stream)
            @test read(stream, UInt8) === 0x01
            @test !eof(stream)
            @test read(stream, UInt8) === 0x02
            @test !eof(stream)
            @test read(stream) == [0x03, 0x04, 0x05]
            @test eof(stream)

            @test isopen(stream)
            @test isopen(input)
            close(stream)
            @test !isopen(stream)
            @test !isopen(input)
        end
    end

    @testset "BufferedInputStream: immobilized buffer" begin
        stream = BufferedInputStream(IOBuffer("abcdefg"), 2)
        stream.immobilized = false
        @assert read(stream, UInt8) == UInt8('a')
        mark(stream)
        @assert read(stream, UInt8) == UInt8('b')
        BufferedStreams.fillbuffer!(stream)
        @test stream.buffer[1] == UInt8('b')

        stream = BufferedInputStream(IOBuffer("abcdefg"), 2)
        stream.immobilized = true
        @assert read(stream, UInt8) == UInt8('a')
        mark(stream)
        @assert read(stream, UInt8) == UInt8('b')
        BufferedStreams.fillbuffer!(stream)
        @test stream.buffer[2] == UInt8('b')

        stream = BufferedInputStream(IOBuffer("abcdefg"), 6)
        stream.immobilized = true
        data = Vector{UInt8}(undef, 7)
        BufferedStreams.readbytes!(stream, data, 1, 3)
        @test data[1:3] == b"abc"
        BufferedStreams.readbytes!(stream, data, 4, 7)
        @test data[4:7] == b"defg"
    end

    @testset "BufferedInputStream: shiftdata!" begin
        stream = BufferedInputStream(IOBuffer("abcdefg"), 2)
        read(stream, 1)
        @test BufferedStreams.shiftdata!(stream) > 0
        read(stream, 2)
        @test BufferedStreams.shiftdata!(stream) > 0
    end

    @testset "BufferedInputStream: misc." begin
        stream = BufferedInputStream(IOBuffer("foobar"), 10)
        @test !BufferedStreams.ensurebuffered!(stream, 10)
        repr_regex = r"^BufferedInputStream{.*}\(<.* \d+% filled>\)$"
        @test occursin(repr_regex, repr(stream))

        stream = BufferedInputStream(IOBuffer("foobar"), 4 * 2^10)
        @test occursin(repr_regex, repr(stream))
        @test occursin(r"KiB", repr(stream))

        close(stream)
        @test occursin(r"^BufferedInputStream{.*}\(<closed>\)$", repr(stream))
        @test_throws ArgumentError BufferedInputStream(IOBuffer("foo"), 0)
    end

    @testset "BufferedInputStream: massive read" begin
        byte = 0x34
        bufsize = 1024
        stream = BufferedInputStream(InfiniteStream(byte), bufsize)

        # read byte by byte
        ok = true
        for i in 1:2^30
            ok = ok && (read(stream, UInt8) == byte)
        end
        @test ok
        @test length(stream.buffer) == 1024

        # read in one shot
        @test all(read(stream, 5 * bufsize) .== byte)
        @test length(stream.buffer) == 1024
    end

    @testset "BufferedInputStream: readavailable" begin
        stream = BufferedInputStream(IOBuffer("some data"))
        @test readavailable(stream) == b"some data"
    end

    @testset "BufferedInputStream: copyuntil" begin
        # note: readlines calls readuntil which calls copyline,
        # which calls copyuntil for keep=true, in Julia 1.11
        data = join(randstring(rand(0:32))*(rand(Bool) ? "\n" : "\r\n")
                    for n=0:100) * "\n\r\n\r\r\r\r\nfooooooobar"
        for bufsize in (1, 3, 7, 128), keep in (true, false)
            s = BufferedInputStream(IOBuffer(data), bufsize)
            @test readlines(s; keep) == readlines(IOBuffer(data); keep)
        end
    end

    @testset "BufferedInputStream: read/peek/skipchars" begin
        ascii = randstring(100)
        unicode = randstring("xα∆🐨", 100) * 'β' # mix of 1/2/3/4-byte chars
        invalid = String(rand(UInt8, 100)) # contains invalid UTF-8 data
        for data in (ascii, unicode, invalid), bufsize in (1,2,4,15,1024)
            io = BufferedInputStream(IOBuffer(data), bufsize)
            @test join(collect(readeach(io, Char))) == data
        end
        for bufsize in (1,2,3,4,15)
            data = "xα∆🐨" * unicode * invalid
            io = BufferedInputStream(IOBuffer(data), bufsize)
            for c in data
                @test peek(io, Char) == peek(io, Char) == c
                @test read(io, Char) == c
            end
        end
        for bufsize in (1,2,3,4,15), c in "xα∆🐨", n in 1:5, linecomment in (nothing, '#')
            data = c^n * "#" * c^n * "\r\n" * "😄😢"
            io = BufferedInputStream(IOBuffer(data), bufsize)
            @test skipchars(==(c), io; linecomment) === io
            @test read(io, Char) == (isnothing(linecomment) ? '#' : '😄')
        end
    end
# end

# Uncommenting top-level testset makes the tests take ~100x longer
# @testset "BufferedOutputStream" begin
    @testset "BufferedOutputStream: write" begin
        data = rand(UInt8, 1000000)
        stream1 = BufferedOutputStream()
        sink = IOBuffer()
        stream2 = BufferedOutputStream(sink, 1024)
        for c in data
            write(stream1, c)
            write(stream2, c)
        end
        flush(stream1)
        flush(stream2)
        @test take!(stream1) == data
        @test take!(sink) == data
        close(stream1)
        close(stream2)
        @test !isopen(sink)
    end

    @testset "BufferedOutputStream: arrays" begin
        expected = UInt8[]
        stream1 = BufferedOutputStream()
        sink = IOBuffer()
        stream2 = BufferedOutputStream(sink, 1024)
        for _ in 1:1000
            data = rand(UInt8, rand(1:1000))
            append!(expected, data)
            write(stream1, data)
            write(stream2, data)
        end
        flush(stream1)
        flush(stream2)
        @test take!(stream1) == expected
        @test take!(sink) == expected
        close(stream1)
        close(stream2)
    end

    @testset "BufferedOutputStream: takebuf_string" begin
        data = rand('A':'z', 1000000)
        iobuf = IOBuffer()
        stream = BufferedOutputStream()
        for c in data
            write(stream, c)
            write(iobuf, c)
        end
        @test String(take!((stream))) == String(take!((iobuf)))
    end

    @testset "BufferedOutputStream: write_result" begin
        sink = IOBuffer()
        stream = BufferedOutputStream(sink, 16)
        for len in 0:10:100
            result = write(stream, repeat("x", len))
            @test result == len
        end
    end

    @testset "BufferedOutputStream: close" begin
        iobuffer = IOBuffer()
        stream = BufferedOutputStream(iobuffer)
        @test isopen(stream)
        @test isopen(iobuffer)
        write(stream, 0x00)
        close(stream)
        @test !isopen(stream)
        @test !isopen(iobuffer)
        @test_throws Exception write(stream, 0x00)
    end

    @testset "BufferedOutputStream: vector sink" begin
        sink = UInt8[]
        stream = BufferedOutputStream(sink)
        write(stream, 0x00)
        write(stream, 0x01)
        write(stream, 0x02)
        flush(stream)
        @test take!(stream) == [0x00, 0x01, 0x02]
        @test isopen(stream)
        close(stream)
        @test !isopen(stream)
        @test_throws Exception write(stream, 0x00)
    end

    @testset "BufferedOutputStream: iostream" begin
        mktemp() do path, out
            stream = BufferedOutputStream(out, 10)
            write(stream, "hello")
            @test stat(path).size == 0
            write(stream, "world")
            @test stat(path).size == 0
            write(stream, "!")
            # BufferedOutputStream buffer has run out of space,
            # but IOStream buffer has not
            @test stat(path).size == 0
            flush(stream)
            @test stat(path).size == 11
            write(stream, "...")
            @test stat(path).size == 11
            close(stream)
            @test !isopen(out)
            @test stat(path).size == 14
        end
    end

    @testset "BufferedOutputStream: position" begin
        iob = IOBuffer()
        sink = IOBuffer()
        stream = BufferedOutputStream(sink, 16)
        for len in 0:10:100
            write(stream, repeat("x", len))
            write(iob, repeat("x", len))
            @test position(stream) == position(iob)
        end
        close(stream)
        close(iob)
        @test position(stream) == position(sink) == position(iob)

        mktemp() do path, sink
            stream = BufferedOutputStream(sink, 16)
            pos = 0
            for len in 0:10:100
                write(stream, repeat("x", len))
                pos += len
                @test position(stream) == pos
            end
        end
    end

    @testset "BufferedOutputStream: misc." begin
        stream = BufferedOutputStream(IOBuffer(), 5)
        @test eof(stream)
        @test pointer(stream) == pointer(stream.buffer)
        @test occursin(r"^BufferedOutputStream{.*}\(<.* \d+% filled>\)$", string(stream))
        close(stream)
        @test occursin(r"^BufferedOutputStream{.*}\(<closed>\)$", string(stream))
        @test_throws ArgumentError BufferedOutputStream(IOBuffer(), 0)
    end
# end
