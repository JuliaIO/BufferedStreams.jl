var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#BufferedStreams-1",
    "page": "Home",
    "title": "BufferedStreams",
    "category": "section",
    "text": "(Image: )  (Image: )  (Image: )  (Image: ) (Image: Lifecycle) (Image: Chat on Discord)"
},

{
    "location": "index.html#Description-1",
    "page": "Home",
    "title": "Description",
    "category": "section",
    "text": "BufferedStreams provides buffering for IO operations. It can wrap any IO type automatically making incremental reading and writing faster."
},

{
    "location": "index.html#Installation-1",
    "page": "Home",
    "title": "Installation",
    "category": "section",
    "text": "using Pkg\nadd(\"BufferedStreams\")\n# Pkg.add(\"BufferedStreams\") on julia prior to v0.7If you are interested in the cutting edge of the development, please check out the master branch to try new features before release."
},

{
    "location": "index.html#Testing-1",
    "page": "Home",
    "title": "Testing",
    "category": "section",
    "text": "BufferedStreams is tested against Julia 0.7 and 1.0 on Linux, OS X, and Windows.PackageEvaluator Latest Build Status\n(Image: ) (Image: ) (Image: ) (Image: ) (Image: )"
},

{
    "location": "index.html#Contributing-1",
    "page": "Home",
    "title": "Contributing",
    "category": "section",
    "text": "We appreciate contributions from users including reporting bugs, fixing issues, improving performance and adding new features.Take a look at the CONTRIBUTING file provided with every BioJulia package package for detailed contributor and maintainer guidelines."
},

{
    "location": "index.html#Financial-contributions-1",
    "page": "Home",
    "title": "Financial contributions",
    "category": "section",
    "text": "We also welcome financial contributions in full transparency on our open collective. Anyone can file an expense. If the expense makes sense for the development of the community, it will be \"merged\" in the ledger of our open collective by the core contributors and the person who filed the expense will be reimbursed."
},

{
    "location": "index.html#Backers-and-Sponsors-1",
    "page": "Home",
    "title": "Backers & Sponsors",
    "category": "section",
    "text": "Thank you to all our backers and sponsors!Love our work and community? Become a backer.(Image: backers)Does your company use BioJulia? Help keep BioJulia feature rich and healthy by sponsoring the project Your logo will show up here with a link to your website.(Image: ) (Image: ) (Image: ) (Image: ) (Image: ) (Image: ) (Image: ) (Image: ) (Image: ) (Image: )"
},

{
    "location": "index.html#Questions?-1",
    "page": "Home",
    "title": "Questions?",
    "category": "section",
    "text": "If you have a question about contributing or using BioJulia software, come on over and chat to us on Discord, or you can try the Bio category of the Julia discourse site."
},

{
    "location": "inputstreams.html#",
    "page": "Input Streams",
    "title": "Input Streams",
    "category": "page",
    "text": "CurrentModule = BufferedStreams\nDocTestSetup = quote\n    using BufferedStreams\nend"
},

{
    "location": "inputstreams.html#BufferedInputStream-1",
    "page": "Input Streams",
    "title": "BufferedInputStream",
    "category": "section",
    "text": "BufferedInputStream(open(filename)) # wrap an IOStream\nBufferedInputStream(rand(UInt8, 100)) # wrap a byte arrayBufferedInputStream wraps a source. A source can be any IO object, but more specifically it can be any type T that implements a function:BufferedStreams.readbytes!(source::T, buffer::Vector{UInt8}, from::Int, to::Int)This function should write new data to buffer starting at position from and not exceeding position to and return the number of bytes written.BufferedInputStream is itself an IO type and implements the source type so you can use it like any other IO type.Calling close propagates to the underlying source object if applicable; once you wrap an IO object with a buffered stream, you can automatically close it by calling close on the buffered stream. Hence, if you are using a source that requires closing of an underlying system resource like file IO or socket, ensure you implement a close method in your source. This may be important for on-access locking file systems as in the MS Windows OS."
},

{
    "location": "inputstreams.html#Anchors-1",
    "page": "Input Streams",
    "title": "Anchors",
    "category": "section",
    "text": "Input streams also have some tricks to make parsing applications easier. When parsing data incrementally, one must take care that partial matches are preserved across buffer refills. One easy way to do this is to copy it to a temporary buffer, but this unecessary copying can slow things down.Input streams instead support the notion of \"anchoring\", which instructs the stream to save the current position in the buffer. If the buffer gets refilled, then any data in the buffer including or following that position gets shifted over to make room. When the match is finished, one can then call takeanchored! return an array of the bytes from the anchored position to the currened position, or upanchor! to return the index of the anchored position in the buffer.# print all numbers literals from a stream\nstream = BufferedInputStream(source)\nwhile !eof(stream)\n    b = peek(stream)\n    if \'1\' <= b <= \'9\'\n        if !isanchored(stream)\n            anchor!(stream)\n        end\n    elseif isanchored(stream)\n        println(ASCIIString(takeanchored!(stream)))\n    end\n    read(stream, UInt8)\nend"
},

{
    "location": "outputstreams.html#",
    "page": "Output Streams",
    "title": "Output Streams",
    "category": "page",
    "text": "CurrentModule = BufferedStreams\nDocTestSetup = quote\n    using BufferedStreams\nend"
},

{
    "location": "outputstreams.html#BufferedOutputStream-1",
    "page": "Output Streams",
    "title": "BufferedOutputStream",
    "category": "section",
    "text": "stream = BufferedOutputStream(open(filename, \"w\")) # wrap an IOStreamBufferedOutputStream is the converse to BufferedInputStream, wrapping a sink type. It also works on any writable IO type, as well the more specific sink interface:writebytes(sink::T, buffer::Vector{UInt8}, n::Int, eof::Bool)This function should consume the first n bytes of buffer. The eof argument is used to indicate that there will be no more input to consume. It should return the number of bytes written, which must be n or 0. A return value of 0 indicates data was processed but should not be evicted from the buffer."
},

{
    "location": "outputstreams.html#BufferedOutputStream-as-an-alternative-to-IOBuffer-1",
    "page": "Output Streams",
    "title": "BufferedOutputStream as an alternative to IOBuffer",
    "category": "section",
    "text": "BufferedOutputStream can be used as a simpler and often faster alternative to IOBuffer for incrementally building strings.out = BufferedOutputStream()\nprint(out, \"Hello\")\nprint(out, \" World\")\nstr = String(take!(out))"
},

]}
