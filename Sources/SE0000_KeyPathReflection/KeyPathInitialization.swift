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

import KeyPathReflection_CShims

// This is a utility within KeyPath.swift in the standard library. If this
// gets moved into there, then this goes away, but will have to rethink if this
// goes into a different module.
extension AnyKeyPath {
  internal static func _create(
    capacityInBytes bytes: Int,
    initializedBy body: (UnsafeMutableRawBufferPointer) -> ()
  ) -> Self {
    assert(bytes > 0 && bytes % 4 == 0,
           "capacity must be multiple of 4 bytes")
    let metadata = getMetadata(for: self) as! ClassMetadata
    var size = metadata.instanceSize
    
    let tailStride = MemoryLayout<Int32>.stride
    let tailAlignMask = MemoryLayout<Int32>.alignment - 1
    
    size += tailAlignMask
    size &= ~tailAlignMask
    size += tailStride * (bytes / 4)
    
    let alignment = metadata.instanceAlignMask | tailAlignMask
    
    let object = swift_allocObject(
      UnsafeMutableRawPointer(mutating: metadata.pointer),
      size,
      alignment
    )
    
    guard object != nil else {
      fatalError("Allocating \(self) instance failed for keypath reflection")
    }
    
    // This memory layout of Int by 2 is the size of a heap object which object
    // points to. Tail members appear immediately afterwards.
    let base = object! + MemoryLayout<Int>.size * 2
    
    // The first word is the kvc string pointer. Set it to 0 (nil).
    base.storeBytes(of: 0, as: Int.self)
    
    // Return an offseted base after the kvc string pointer.
    let newBase = base + MemoryLayout<Int>.size
    let newBytes = bytes - MemoryLayout<Int>.size
    
    body(UnsafeMutableRawBufferPointer(start: newBase, count: newBytes))
    
    return unsafeBitCast(object, to: self)
  }
}

// Helper struct to represent the keypath buffer header. This structure is also
// found within KeyPath.swift, so if this gets moved there this goes away.
internal struct KeyPathBufferHeader {
  let bits: UInt32
  
  init(hasReferencePrefix: Bool, isTrivial: Bool, size: UInt32) {
    var bits = size
    
    if hasReferencePrefix {
      bits |= 0x40000000
    }
    
    if isTrivial {
      bits |= 0x80000000
    }
    
    self.bits = bits
  }
}

// This initializes the raw keypath buffer with the field offset information.
func instantiateKeyPathBuffer(
  _ metadata: TypeMetadata,
  _ leafIndex: Int,
  _ data: UnsafeMutableRawBufferPointer
) {
  let header = KeyPathBufferHeader(
    hasReferencePrefix: false,
    isTrivial: true,
    size: UInt32(MemoryLayout<UInt32>.size)
  )
  
  data.storeBytes(of: header, as: KeyPathBufferHeader.self)
  
  var componentBits = UInt32(metadata.fieldOffsets[leafIndex])
  componentBits |= metadata.kind == .struct ? 1 << 24 : 3 << 24
  
  data.storeBytes(
    of: componentBits,
    toByteOffset: MemoryLayout<Int>.size,
    as: UInt32.self
  )
}

// Returns a concrete type for which this keypath is going to be given a root
// and leaf type.
func getKeyPathType(
  from root: TypeMetadata,
  for leaf: FieldRecord
) -> AnyKeyPath.Type {
  let leafType = root.type(of: leaf.mangledTypeName)!
  
  func openRoot<Root>(_: Root.Type) -> AnyKeyPath.Type {
    func openLeaf<Value>(_: Value.Type) -> AnyKeyPath.Type {
      if leaf.flags.isVar {
        return root.kind == .class
          ? ReferenceWritableKeyPath<Root, Value>.self
          : WritableKeyPath<Root, Value>.self
      }
      return KeyPath<Root, Value>.self
    }
    
    return _openExistential(leafType, do: openLeaf)
  }
  
  return _openExistential(root.type, do: openRoot)
}

// Given a root type and a leaf index, create a concrete keypath object at
// runtime.
internal func createKeyPath(root: TypeMetadata, leaf: Int) -> AnyKeyPath {
  let field = root.contextDescriptor.fields.records[leaf]
  
  let keyPathTy = getKeyPathType(from: root, for: field)
  let size = MemoryLayout<Int>.size * 3
  let instance = keyPathTy._create(capacityInBytes: size) {
    instantiateKeyPathBuffer(root, leaf, $0)
  }
  
  let heapObj = UnsafeRawPointer(Unmanaged.passUnretained(instance).toOpaque())
  let keyPath = unsafeBitCast(heapObj, to: AnyKeyPath.self)
  return keyPath
}
