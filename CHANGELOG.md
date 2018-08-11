# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2018-08-11
### Changed
- The first major stable release
- Comaptible with julia v0.7 and 1.0.

## [0.4.1] - 2018-07-10
### Changed
- More compatiblity improvements to julia v0.7.

## [0.4.0] - 2018-03-01
### Changed
- Compatibility changes for julia v0.7.

## [0.3.3] - 2017-06-04
### Added
- Extend `Base.unsafe_read` & `Base.nb_available`.

### Changed
- Fixed a double buffering problem.

## [0.3.2] - 2017-03-13
### Changed
- Bugfix of the `readbytes!` method. 

## [0.3.1] - 2017-03-10
### Changed
- Bugfix of the `shiftdata!` method.

## [0.3.0] - 2017-02-07
### Added
- The ability to make buffered data immobile.

### Changed
- Minor code refactors.

## [0.2.3] - 2017-01-18
### Changed
- Fixed lower bound.

## [0.2.2] - 2017-01-17
### Changed
- Bugfixes to takebuf_string methods.

## [0.2.1] - 2017-01-10
### Changed
- Revised takebuf methods, thanks @musm

[Unreleased]: https://github.com/BioJulia/BioCore.jl/compare/v1.3.0...HEAD
[1.0.0]: https://github.com/BioJulia/BufferedStreams.jl/compare/v0.4.1...v1.0.0
[0.4.1]: https://github.com/BioJulia/BufferedStreams.jl/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/BioJulia/BufferedStreams.jl/compare/v0.3.3...v0.4.0
[0.3.3]: https://github.com/BioJulia/BufferedStreams.jl/compare/v0.3.2...v0.3.3
[0.3.2]: https://github.com/BioJulia/BufferedStreams.jl/compare/v0.3.1...v0.3.2
[0.3.1]: https://github.com/BioJulia/BufferedStreams.jl/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/BioJulia/BufferedStreams.jl/compare/v0.2.3...v0.3.0
[0.2.3]: https://github.com/BioJulia/BufferedStreams.jl/compare/v0.2.2...v0.2.3
[0.2.2]: https://github.com/BioJulia/BufferedStreams.jl/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/BioJulia/BufferedStreams.jl/tree/v0.2.1
