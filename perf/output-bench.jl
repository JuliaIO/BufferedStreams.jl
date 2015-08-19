
import BufferedStreams, Zlib, GZip, Libz

# Source:
# ftp://ftp.ensembl.org/pub/release-81/fasta/homo_sapiens/cds/Homo_sapiens.GRCh38.cds.all.fa.gz
const filename = "Homo_sapiens.GRCh38.cds.all.fa"
const data = readall(open(filename))

const methods = [
    ("IOStream",                      () -> open("/dev/null", "w")),
    ("BufferedOutputStream/IOStream", () -> BufferedStreams.BufferedOutputStream(open("/dev/null", "w"))),
    ("BufferedOutputStream",          () -> BufferedStreams.BufferedOutputStream()),
    ("IOBuffer",                      () -> IOBuffer()),
    ("GZip",                          () -> GZip.gzopen("/dev/null", "w")),
    ("Zlib",                          () -> Zlib.Writer(open("/dev/null", "w"))),
    ("Libz",                          () -> Libz.ZlibOutputStream(open("/dev/null", "w"))),
]


function bench(f)
    for (method_name, open_func) in methods
        print("  ", method_name, ":  ")
        f(open_func())
        println(round(f(open_func()), 4))
    end
end


function bench_write(output)
    tic()
    for c in data
        write(output, c)
    end
    close(output)
    return toq()
end


function bench_write_array(output)
    tic()
    write(output, data)
    close(output)
    return toq()
end


println("write")
bench(bench_write)

println("write array")
bench(bench_write_array)
