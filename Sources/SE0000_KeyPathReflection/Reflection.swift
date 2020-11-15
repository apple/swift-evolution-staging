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

public enum Reflection {
  /// Returns the collection of all key paths of this type.
  ///
  /// - Parameter type: The static type to return the stored key paths of.
  /// - Returns: An array of partial key paths for this type.
  public static func allKeyPaths<T>(for type: T.Type) -> [PartialKeyPath<T>] {
    guard let metadata = getMetadata(for: type) as? TypeMetadata else {
      return []
    }
    
    var result = [PartialKeyPath<T>]()
    result.reserveCapacity(metadata.contextDescriptor.fields.numFields)
    
    for i in 0 ..< metadata.contextDescriptor.fields.numFields {
      let keyPath = createKeyPath(root: metadata, leaf: i) as! PartialKeyPath<T>
      result.append(keyPath)
    }
    
    return result
  }
  
  /// Returns the collection of all key paths of this value.
  ///
  /// - Parameter value: A value of any type to return the stored key paths of.
  /// - Returns: An array of partial key paths for this value.
  public static func allKeyPaths<T>(for value: T) -> [PartialKeyPath<T>] {
    // If the value conforms to `_KeyPathIterableBase`, return `allKeyPaths`.
    if let keyPathIterable = value as? _KeyPathIterableBase {
      return keyPathIterable._allKeyPathsTypeErased.compactMap {
        $0 as? PartialKeyPath<T>
      }
    }
    
    // Otherwise, return stored property key paths.
    return allKeyPaths(for: T.self)
  }
  
  /// Returns the collection of all named key paths of this type.
  ///
  /// - Parameter value: A value of any type to return the stored key paths of.
  /// - Returns: An array of tuples with both the name and partial key path
  ///            for this value.
  public static func allNamedKeyPaths<T>(
    for type: T.Type
  ) -> [(name: String, keyPath: PartialKeyPath<T>)] {
    guard let metadata = getMetadata(for: type) as? TypeMetadata else {
      return []
    }
    
    var result = [(name: String, keyPath: PartialKeyPath<T>)]()
    result.reserveCapacity(metadata.contextDescriptor.fields.numFields)
    
    for i in 0 ..< metadata.contextDescriptor.fields.numFields {
      let name = metadata.contextDescriptor.fields.records[i].name
      let keyPath = createKeyPath(root: metadata, leaf: i) as! PartialKeyPath<T>
      result.append((name: name, keyPath: keyPath))
    }
    
    return result
  }
  
  /// Returns the collection of all named key paths of this value.
  ///
  /// - Parameter value: A value of any type to return the stored key paths of.
  /// - Returns: An array of tuples with both the name and partial key path
  ///            for this value.
  public static func allNamedKeyPaths<T>(
    for value: T
  ) -> [(name: String, keyPath: PartialKeyPath<T>)] {
    // If the value conforms to `_KeyPathIterableBase`, return
    // `allNamedKeyPaths`.
    if let keyPathIterable = value as? _KeyPathIterableBase {
      return keyPathIterable._allNamedKeyPathsTypeErased.compactMap { pair in
        (pair.keyPath as? PartialKeyPath<T>).map { (pair.name, $0) }
      }
    }
    
    // Otherwise, return stored property key paths.
    return allNamedKeyPaths(for: T.self)
  }
}
