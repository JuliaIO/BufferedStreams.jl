# BufferedStreams

[![](https://img.shields.io/github/release/JuliaIO/BufferedStreams.jl.svg?style=flat-square)](https://github.com/JuliaIO/BufferedStreams.jl/releases/latest)
[![](https://img.shields.io/badge/license-MIT-green.svg?style=flat-square)](https://github.com/JuliaIO/BufferedStreams.jl/blob/master/LICENSE)
[![Build Status](https://github.com/JuliaIO/BufferedStreams.jl/workflows/CI/badge.svg)](https://github.com/JuliaIO/BufferedStreams.jl/actions?query=workflows/CI) [![codecov](https://codecov.io/gh/JuliaIO/BufferedStreams.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaIO/BufferedStreams.jl)
[![](https://img.shields.io/badge/docs-stable-blue.svg?style=flat-square)](https://juliaio.github.io/BufferedStreams.jl/stable)


## Description

BufferedStreams provides buffering for IO operations. It can wrap any IO type
automatically making incremental reading and writing faster.


## Installation

```julia
using Pkg
Pkg.add("BufferedStreams")
```
