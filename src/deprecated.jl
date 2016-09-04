using Base.depwarn

typealias EmptyStreamSource EmptyStream

Base.@deprecate EmptyStreamSource EmptyStream
Base.@deprecate seekforward(stream::BufferedInputStream, n::Integer) skip(stream, n)
