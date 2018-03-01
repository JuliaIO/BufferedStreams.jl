```@meta
CurrentModule = BufferedStreams
DocTestSetup = quote
    using BufferedStreams
end
```
# BufferedInputStream


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
by calling `close` on the buffered stream. Hence, if you are using a source that
requires closing of an underlying system resource like file IO or socket, ensure
you implement a `close` method in your source. This may be important for
on-access locking file systems as in the MS Windows OS.

## Anchors

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
