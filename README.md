# IsPower

> **Note:** This package is a part of a Swift Evolution proposal for
  inclusion in the Swift standard library, and is not intended for use in
  production code at this time.

* Proposal: [SE-0288](https://github.com/apple/swift-evolution/blob/main/proposals/0288-binaryinteger-ispower.md)
* Author: [Ding Ye](https://github.com/dingobye)


## Introduction

This package adds a public API `isPower(of:)`, as an extension method, to the
`BinaryInteger` protocol. It checks if an integer is power of another.

```swift
import SE0288_IsPower

let x: Int = Int.random(in: 0000..<0288)
1.isPower(of: x)      // 'true' since x^0 == 1

let y: UInt = 1000
y.isPower(of: 10)  // 'true' since 10^3 == 1000

(-1).isPower(of: 1)   // 'false'

(-32).isPower(of: -2) // 'true' since (-2)^5 == -32
```


## Usage

To use this library in a Swift Package Manager project,
add the following to your `Package.swift` file's dependencies:

```swift
.package(
    url: "https://github.com/apple/swift-evolution-staging.git",
    .branch("SE0288_IsPower")),
```


