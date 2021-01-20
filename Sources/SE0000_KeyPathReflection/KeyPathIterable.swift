//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

// An implementation detail of `KeyPathIterable`; do not use this protocol
// directly.
public protocol _KeyPathIterableBase {
  var _allNamedKeyPathsTypeErased: [(name: String, keyPath: AnyKeyPath)] { get }
}

extension _KeyPathIterableBase {
  public var _allKeyPathsTypeErased: [AnyKeyPath] {
    return _allNamedKeyPathsTypeErased.map { $0.keyPath }
  }
}

/// A type whose values provides custom key paths to properties or elements.
public protocol KeyPathIterable: _KeyPathIterableBase {
  /// A collection of all custom key paths of this value.
  var allNamedKeyPaths: [(name: String, keyPath: PartialKeyPath<Self>)] { get }
}

extension KeyPathIterable {
  /// A collection of all custom key paths of this value.
  public var allKeyPaths: [PartialKeyPath<Self>] {
    return allNamedKeyPaths.map { $0.keyPath }
  }
}

extension KeyPathIterable {
  public var _allNamedKeyPathsTypeErased: [(name: String, keyPath: AnyKeyPath)] {
    return allNamedKeyPaths.map { ($0.name, $0.keyPath as AnyKeyPath) }
  }
}

internal func areWritable<Root, Value>(
  _ namedKeyPaths: [(name: String, keyPath: PartialKeyPath<Root>)],
  valueType: Value.Type
) -> Bool {
  return !namedKeyPaths.contains {
    !($0.keyPath is WritableKeyPath<Root, Value>)
  }
}

extension Optional: KeyPathIterable {
  public var allNamedKeyPaths: [(name: String, keyPath: PartialKeyPath<Optional>)] {
    if self == nil {
        return []
    } else {
        return [("value", \Optional.!)]
    }
  }
}

extension Array: KeyPathIterable {
  public var allNamedKeyPaths: [(name: String, keyPath: PartialKeyPath<Array>)] {
    let result = indices.map { i in (i.description, \Array[i]) }
    assert(areWritable(result, valueType: Element.self))
    return result
  }
}

// `Dictionary` conforms to `KeyPathIterable` when `Key` is
// `CustomStringConvertible`.

extension Dictionary: _KeyPathIterableBase where Key: CustomStringConvertible {}

extension Dictionary: KeyPathIterable where Key: CustomStringConvertible {
  public var allNamedKeyPaths:
      [(name: String, keyPath: PartialKeyPath<Dictionary>)] {
    // Note: `Dictionary.subscript(_: Key)` returns `Value?` and can be used to
    // form `WritableKeyPath<Self, Value>` key paths. Force-unwrapping the
    // result is necessary so that the key path value type is `Value`, not
    // `Value?`.
    let result = keys.map { ("\($0)", \Dictionary[$0]!) }
    assert(areWritable(result, valueType: Value.self))
    return result
  }
}
