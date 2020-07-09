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

internal protocol RelativePointer {
  associatedtype Pointee
  
  var offset: Int32 { get }
  
  func address(from ptr: UnsafeRawPointer) -> UnsafePointer<Pointee>
  func pointee(from ptr: UnsafeRawPointer) -> Pointee?
}

extension RelativePointer {
  func address(from ptr: UnsafeRawPointer) -> UnsafePointer<Pointee> {
    UnsafePointer<Pointee>((ptr + Int(offset))._rawValue)
  }
}

internal struct RelativeDirectPointer<Pointee>: RelativePointer {
  let offset: Int32

  func pointee(from ptr: UnsafeRawPointer) -> Pointee? {
    guard offset != 0 else {
      return nil
    }
    
    return address(from: ptr).pointee
  }
}

extension UnsafeRawPointer {
  func relativeDirect<T>(as type: T.Type) -> UnsafePointer<T> {
    let relativePointer = RelativeDirectPointer<T>(
      offset: load(as: Int32.self)
    )
    return relativePointer.address(from: self)
  }
}

internal struct RelativeIndirectPointer<T>: RelativePointer {
  typealias Pointee = UnsafePointer<T>
  
  let offset: Int32

  func pointee(from ptr: UnsafeRawPointer) -> Pointee? {
    guard offset != 0 else {
      return nil
    }
    
    return address(from: ptr).pointee
  }
}

internal struct RelativeIndirectablePointer<Pointee>: RelativePointer {
  let offset: Int32

  func address(from ptr: UnsafeRawPointer) -> UnsafePointer<Pointee> {
    UnsafePointer<Pointee>((ptr + Int(offset & ~1))._rawValue)
  }
  
  func pointee(from ptr: UnsafeRawPointer) -> Pointee? {
    guard offset != 0 else {
      return nil
    }
    
    if offset & 1 == 1 {
      let pointer = UnsafeRawPointer(address(from: ptr))
                      .load(as: UnsafePointer<Pointee>.self)
      return pointer.pointee
    } else {
      return address(from: ptr).pointee
    }
  }
}
