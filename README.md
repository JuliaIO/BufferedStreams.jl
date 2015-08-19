
# BufferedStreams

BufferedStreams provides buffering for IO operations. You can think of it as a
alterative IO system in which many things are magically faster.

[Libz.jl](https://github.com/dcjones/Libz.jl) is the initial application, but
the same interface can be used to implement fast IO for a variety of sources and
sinks.

This is still somewhat experimental. More exposition to come.

# Benchmarks

See `perf/input-bench.jl` and `perf/output-bench.jl`. These are somewhat
unscientific. IO benchmarks in particular can vary a lot from run to run, but
these should provide a vague idea of performance.

## Reading

Note: gzip/libz/zlib are reading and decompressing gzipped data

 read array | time (in seconds)
------------|--------------------
IOStream |  0.0459
BufferedInputStream/IOStream |  0.2096
BufferedInputStream/Mmap |  0.1488
IOBuffer/Mmap |  0.1504
GZip |  27.0333
Zlib |  0.6128
Libz |  0.5517
Libz/Mmap |  0.5465
GZBufferedStream |  0.996
Pipe/gzip |  0.5


 read bytes | time (in seconds)
------------|---------------------
IOStream |  1.3757
BufferedInputStream/IOStream |  0.3433
BufferedInputStream/Mmap |  0.0931
IOBuffer/Mmap |  0.1365
GZip |  27.4463
Zlib |  6.0401
Libz |  0.4414
Libz/Mmap |  0.4458
GZBufferedStream |  0.4702
Pipe/gzip |  56.6504


 read line | time (in seconds)
-----------|--------------------
IOStream |  0.6803
BufferedInputStream/IOStream | 0.7044
BufferedInputStream/Mmap |  0.7204
IOBuffer/Mmap |  0.8893
GZip |  1.622
Zlib |  3.68
Libz |  0.9922
Libz/Mmap |  1.0185
GZBufferedStream | 2.5571
Pipe/gzip |  2.3483


## Writing

Note: gzip/libz/zlib are writing and compressing the data

 write bytes | time (in seconds)
-------------|--------------------
IOStream | 2.4753
BufferedOutputStream/IOStream |  1.0234
BufferedOutputStream |  1.2023
IOBuffer |  3.3693
GZip |  19.5671
Zlib |  80.3204
Libz |  13.3319


 write array | time (in seconds)
------------| ------------------
IOStream |  0.0794
BufferedOutputStream/IOStream |  0.071
BufferedOutputStream |  0.116
IOBuffer |  0.0959
GZip |  12.2057
Zlib |  48.1427
Libz |  12.2098


