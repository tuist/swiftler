# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Rustler-style integration - no need to add `:swift` to compilers list
- Automatic Swift compilation during module compilation
- External resource tracking with `@external_resource`
- 30-second timeout for Swift compilation to prevent hanging
- Comprehensive documentation with ExDoc
- `mix swiftler.new` task for generating Swift NIF projects
- Support for `@nif` and `#nifLibrary` Swift macros
- Type validation at compile time

### Changed
- Terminology from "crate" to "package" for Swift consistency
- Swift compilation now happens via `__using__` macro
- Improved error messages for better developer experience

### Fixed
- Module loading failures when Swift library doesn't exist
- Compilation hanging on SwiftSyntax dependencies

## [0.1.0] - 2024-01-XX

### Added
- Initial release of Swiftler
- Swift to Elixir NIF integration
- Dynamic library generation using Swift Package Manager
- Mix tasks: `mix swift.compile` and `mix swift.clean`
- Basic type support: integers, doubles, strings, booleans
- Example calculator project
- Swift Testing framework integration
- Automatic recompilation on source changes

### Security
- NIF safety with proper input validation
- Secure Swift Package Manager integration

[Unreleased]: https://github.com/tuist/swiftler/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/tuist/swiftler/releases/tag/v0.1.0