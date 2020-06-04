# SE0000_AdjacentPairs

> **Note:** This package is a part of a Swift Evolution proposal for
  inclusion in the Swift standard library, and is not intended for use in
  production code at this time.

* Proposal: [SE-NNNN](https://github.com/apple/swift-evolution/blob/96b7533ec0fc198bac8f8cf3e5eae7102d3205d2/proposals/NNNN-adjacentpairs.md)
* Author: [Michael Pangburn](https://github.com/mpangburn)


## Introduction

**SE0000_AdjacentPairs** provides a method `adjacentPairs`, available to all types conforming to Sequence,
as well as the supporting `AdjacentPairs` type.

The `AdjacentPairs` wrapper sequence returned by `adjacentPairs` lazily iterates over tuples of adjacent elements: 

```swift
import SE0000_AdjacentPairs

let numbers = (1...5)
let pairs = numbers.adjacentPairs()
// Array(pairs) == [(1, 2), (2, 3), (3, 4), (4, 5)]
```


## Usage

To use this library in a Swift Package Manager project,
add the following to your `Package.swift` file's dependencies:

```swift
.package(
    url: "https://github.com/apple/swift-evolution-staging.git",
    .branch("SE0000_AdjacentPairs")),
```


