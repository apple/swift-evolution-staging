# KeyPath Reflection

> **Note:** This package is a part of a Swift Evolution proposal for
  inclusion in the Swift standard library, and is not intended for use in
  production code at this time.

* Proposal: [SE-NNNN](https://github.com/apple/swift-evolution/proposals/NNNN-filename.md)
* Authors: [Richard Wei](https://github.com/rxwei), [Dan Zheng](https://github.com/dan-zheng), [Alejandro Alonso](https://github.com/Azoy)


## Introduction

This proposal aims to provide a mechanism for users to get key paths to stored properties
of types at runtime.

```swift
struct Dog {
  let age: Int
  let name: String
}

let dogKeyPaths = Reflection.allKeyPaths(for: Dog.self)

let sparky = Dog(age: 128, name: "Sparky")

for dogKeyPath in dogKeyPaths {
  print(sparky[keyPath: dogKeyPath]) // 128, Sparky
}
```

Of course, this also works with instances at runtime:

```swift
let nums = [1, 2, 3, 4]
let numKeyPaths = Reflection.allKeyPaths(for: nums)

for numKeyPath in numKeyPaths {
  print(nums[keyPath: numKeyPath]) // 1, 2, 3, 4
}
```

## Usage

To use this library in a Swift Package Manager project,
add the following to your `Package.swift` file's dependencies:

```swift
.package(
    url: "https://github.com/apple/swift-evolution-staging.git",
    .branch("reflection")
)
```


