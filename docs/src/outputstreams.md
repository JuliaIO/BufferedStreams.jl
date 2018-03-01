```@meta
CurrentModule = BufferedStreams
DocTestSetup = quote
    using BufferedStreams
end
```
# BufferedOutputStream

```@example
stream = BufferedOutputStream(open(filename, "w")) # wrap an IOStream
nothing # hide
```

`BufferedOutputStream` is the converse to `BufferedInputStream`, wrapping a sink
type. It also works on any writable `IO` type, as well the more specific sink
interface:

```@example
writebytes(sink::T, buffer::Vector{UInt8}, n::Int, eof::Bool)
nothing # hide
```

This function should consume the first `n` bytes of `buffer`. The `eof` argument
is used to indicate that there will be no more input to consume. It should
return the number of bytes written, which must be `n` or 0. A return value of 0
indicates data was processed but should not be evicted from the buffer.


## `BufferedOutputStream` as an alternative to `IOBuffer`

`BufferedOutputStream` can be used as a simpler and often faster alternative to
`IOBuffer` for incrementally building strings.

```@example
out = BufferedOutputStream()
print(out, "Hello")
print(out, " World")
str = String(take!(out))
```
