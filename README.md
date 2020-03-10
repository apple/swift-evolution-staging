# CircularBuffer

> **Note:** This package is a part of a Swift Evolution proposal for
  inclusion in the Swift standard library, and is not intended for use in
  production code at this time.

* Proposal: [SE-NNNN](https://github.com/apple/swift-evolution/proposals/NNNN-filename.md)
* Author(s): [Maksim Kita](https://github.com/kitaisreal)


## Introduction

```swift
import SE0000_CircularBuffer
```

An ordered, random-access collection.

You can use circular buffer instead of an array when you need fast
front and back insertions and deletion together with fast subsript
element access.

When CircularBuffer is full, new data will be written to the beginning
and old will be overridden.

Example:
```swift
var circularBuffer = CircularBuffer<Int>(capacity: 2)
circularBuffer.pushBack(1)
circularBuffer.pushBack(2)

print(circularBuffer)
// Prints "[1, 2]"
circularBuffer.pushBack(3)

print(circularBuffer)
// Prints "[2, 3]"
```

You can manually increase CircularBuffer size using resize(newCapacity: ) method

Example:
```swift
var circularBuffer = CircularBuffer<Int>(capacity: 2)
circularBuffer.pushBack(1)
circularBuffer.pushBack(2)
circularBuffer.pushBack(3)
print(circularBuffer)
// Prints "[2, 3]"

circularBuffer.resize(newCapacity: 3)
circularBuffer.pushBack(4)
print(circularBuffer)
// Prints "[2, 3, 4]"
```

CircularBuffer supports both front and back insertion and deletion.
```swift
var circularBuffer = CircularBuffer<Int>(capacity: 2)
circularBuffer.pushBack(1)
circularBuffer.pushFront(2)
print(circularBuffer)
// Prints "[2, 3]"
// Now buffer isFull so next
// writes will override data at beggining

circularBuffer.pushFront(4)
print(circularBuffer)
// Prints "[4, 2]"

circularBuffer.pushBack(3)
print(circularBuffer)
// Prints "[2, 3]"

circularBuffer.popFront()
print(circularBuffer)
// Prints "[3]"

circularBuffer.popBack()
print(circularBuffer)
// Prints "[]"
```

## Usage

To use this library in a Swift Package Manager project,
add the following to your `Package.swift` file's dependencies:

```swift
.package(
    url: "https://github.com/apple/swift-evolution-staging.git",
    .branch("SE0000_PackageName")),
```


