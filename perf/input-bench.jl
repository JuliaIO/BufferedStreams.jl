

import BufferedStreams, Zlib, GZip, Libz
include("gzbufferedstream.jl")

# Source:
# ftp://ftp.ensembl.org/pub/release-81/fasta/homo_sapiens/cds/Homo_sapiens.GRCh38.cds.all.fa.gz
const filename = "Homo_sapiens.GRCh38.cds.all.fa"
const gzfilename = "Homo_sapiens.GRCh38.cds.all.fa.gz"


const methods = [
    ("IOStream",                      () -> open(filename)),
    ("BufferedInputStream/IOStream",  () -> BufferedStreams.BufferedInputStream(open(filename))),
    ("BufferedInputStream/Mmap",      () -> BufferedStreams.BufferedInputStream(
                                                Mmap.mmap(open(filename), Vector{UInt8}, (filesize(filename),)))),
    ("IOBuffer/Mmap",                 () -> IOBuffer(Mmap.mmap(open(filename), Vector{UInt8}, (filesize(filename),)))),
    ("GZip",                          () -> GZip.gzopen(gzfilename)),
    ("Zlib",                          () -> Zlib.Reader(open(gzfilename))),
    ("Libz",                          () -> Libz.ZlibInflateInputStream(open(gzfilename))),
    ("Libz/Mmap",                     () -> Libz.ZlibInflateInputStream(
                                                 Mmap.mmap(open(gzfilename), Vector{UInt8}, (filesize(gzfilename),)))),
    ("GZBufferedStream",              () -> GZBufferedStream(gzopen(gzfilename))),
    ("Pipe/gzip",                     () -> open(`gzip -cd $gzfilename`)[1]),
    #("BufferedInputStream/Pipe/gzip", () -> BufferedStreams.BufferedInputStream(open(`gzip -cd $gzfilename`)[1])),
]


function bench(f)
    for (method_name, open_func) in methods
        print("  ", method_name, ":  ")
        f(open_func())
        println(round(f(open_func()), 4))
    end
end


function bench_readbytes(input)
    tic()
    readbytes(input)
    return toq()
end


function bench_read(input)
    tic()
    while !eof(input)
        read(input, UInt8)
    end
    return toq()
end


function bench_readline(input)
    tic()
    for line in eachline(input)
    end
    return toq()
end


println("readbytes")
bench(bench_readbytes)

println("read")
bench(bench_read)

println("readline")
bench(bench_readline)

