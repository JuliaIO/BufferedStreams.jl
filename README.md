# BufferedStreams

[![Diagram of locks](https://biojulia.github.io/BufferedStreams.jl/locks.gif)](https://www.pc.gc.ca/eng/lhn-nhs/qc/annedebellevue/natcul/natcul2/b.aspx)

| **Release**                                                     | **Documentation**                                                               | **Maintainers**                             |
|:---------------------------------------------------------------:|:-------------------------------------------------------------------------------:|:-------------------------------------------:|
| [![](https://img.shields.io/github/release/BioJulia/BufferedStreams.jl.svg)](https://github.com/BioJulia/BufferedStreams.jl/releases/latest) [![](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/BioJulia/BufferedStreams.jl/blob/master/LICENSE) | [![](https://img.shields.io/badge/docs-stable-blue.svg)](https://biojulia.github.io/BufferedStreams.jl/stable) [![](https://img.shields.io/badge/docs-latest-blue.svg)](https://biojulia.github.io/BufferedStreams.jl/latest) | ![](https://img.shields.io/badge/BioJulia%20Maintainer-Ward9250-orange.svg) |


## Description

BufferedStreams provides buffering for IO operations. It can wrap any IO type
automatically making incremental reading and writing faster.


## Installation

```julia
using Pkg
add("BufferedStreams")
# Pkg.add("BufferedStreams") on julia v0.6-
```

If you are interested in the cutting edge of the development, please check out
the master branch to try new features before release.


## Testing

BufferedStreams.jl is tested against Julia `0.6` and current `0.7-dev` on Linux, OS X, and Windows.

| **PackageEvaluator**                                            | **Latest Build Status**                                                                                |
|:---------------------------------------------------------------:|:------------------------------------------------------------------------------------------------------:|
| [![](https://pkg.julialang.org/badges/BufferedStreams_0.6.svg)](https://pkg.julialang.org/detail/BufferedStreams) [![](https://pkg.julialang.org/badges/BufferedStreams_0.7.svg)](https://pkg.julialang.org/detail/BufferedStreams) | [![](https://img.shields.io/travis/BioJulia/BufferedStreams.jl/master.svg?label=Linux+/+macOS)](https://travis-ci.org/BioJulia/BufferedStreams.jl) [![](https://ci.appveyor.com/api/projects/status/0f7jv901adjmp8o7?svg=true)](https://ci.appveyor.com/project/Ward9250/bufferedstreams-jl/branch/master) [![](https://codecov.io/gh/BioJulia/BufferedStreams.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/BioJulia/BufferedStreams.jl) |


## Contributing and Questions

We appreciate contributions from users including reporting bugs, fixing issues,
improving performance and adding new features.
Please go to the [contributing section of the documentation](https://biojulia.net/Contributing/latest)
for more information.

If you have a question about
contributing or using this package, you are encouraged to use the
[Bio category of the Julia discourse
site](https://discourse.julialang.org/c/domain/bio).
