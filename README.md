[![Diagram of locks](https://biojulia.github.io/BufferedStreams.jl/locks.gif)](http://www.pc.gc.ca/eng/lhn-nhs/qc/annedebellevue/natcul/natcul2/b.aspx)
[![Build Status](https://travis-ci.org/BioJulia/BufferedStreams.jl.svg?branch=master)](https://travis-ci.org/BioJulia/BufferedStreams.jl)
[![codecov.io](http://codecov.io/github/BioJulia/BufferedStreams.jl/coverage.svg?branch=master)](http://codecov.io/github/BioJulia/BufferedStreams.jl?branch=master)

BufferedStreams provides buffering for IO operations. It can wrap any IO type
automatically making incremental reading and writing faster.


## BufferedInputStream

```julia
BufferedInputStream(open(filename)) # wrap an IOStream
BufferedInputStream(rand(UInt8, 100)) # wrap a byte array
```

`BufferedInputStream` wraps a source. A source can be any `IO` object, but more
specifically it can be any type `T` that implements a function:
```julia
BufferedStreams.readbytes!(source::T, buffer::Vector{UInt8}, from::Int, to::Int)
```

This function should write new data to `buffer` starting at position `from` and
not exceeding position `to` and return the number of bytes written.

`BufferedInputStream` is itself an `IO` type and implements the source type so
you can use it like any other `IO` type.

Calling `close` propagates to the underlying source object if applicable; once
you wrap an `IO` object with a buffered stream, you can automatically close it
by calling `close` on the buffered stream.


### Anchors

Input streams also have some tricks to make parsing applications easier. When
parsing data incrementally, one must take care that partial matches are
preserved across buffer refills. One easy way to do this is to copy it to a
temporary buffer, but this unecessary copying can slow things down.

Input streams instead support the notion of "anchoring", which instructs the
stream to save the current position in the buffer. If the buffer gets refilled,
then any data in the buffer including or following that position gets shifted
over to make room. When the match is finished, one can then call `takeanchored!`
return an array of the bytes from the anchored position to the currened
position, or `upanchor!` to return the index of the anchored position in the
buffer.

```julia
# print all numbers literals from a stream
stream = BufferedInputStream(source)
while !eof(stream)
    b = peek(stream)
    if '1' <= b <= '9'
        if !isanchored(stream)
            anchor!(stream)
        end
    elseif isanchored(stream)
        println(ASCIIString(takeanchored!(stream)))
    end

    read(stream, UInt8)
end
```


## BufferedOutputStream

```julia
stream = BufferedOutputStream(open(filename, "w")) # wrap an IOStream
```

`BufferedOutputStream` is the converse to `BufferedInputStream`, wrapping a sink
type. It also works on any writable `IO` type, as well the more specific sink
interface:

```julia
writebytes(sink::T, buffer::Vector{UInt8}, n::Int, eof::Bool)
```

This function should consume the first `n` bytes of `buffer`. The `eof` argument
is used to indicate that there will be no more input to consume. It should
return the number of bytes written, which must be `n` or 0. A return value of 0
indicates data was processed but should not be evicted from the buffer.


### `BufferedOutputStream` as an alternative to `IOBuffer`

`BufferedOutputStream` can be used as a simpler and often faster alternative to
`IOBuffer` for incrementally building strings.

```julia
out = BufferedOutputStream()
print(out, "Hello")
print(out, " World")
str = String(take!(out))
```
