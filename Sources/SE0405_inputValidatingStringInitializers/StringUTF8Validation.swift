//===--- StringUTF8Validation.swift ---------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

//**********                                                **********
//********** This file is copied from the swift repository. **********
//**********                                                **********

import Swift

private func _isUTF8MultiByteLeading(_ x: UInt8) -> Bool {
  return (0xC2...0xF4).contains(x)
}

private func _isNotOverlong_F0(_ x: UInt8) -> Bool {
  return (0x90...0xBF).contains(x)
}

private func _isNotOverlong_F4(_ x: UInt8) -> Bool {
  return UTF8.isContinuation(x) && x <= 0x8F
}

private func _isNotOverlong_E0(_ x: UInt8) -> Bool {
  return (0xA0...0xBF).contains(x)
}

private func _isNotOverlong_ED(_ x: UInt8) -> Bool {
  return UTF8.isContinuation(x) && x <= 0x9F
}

internal struct UTF8ExtraInfo: Equatable {
  public var isASCII: Bool
}

internal enum UTF8ValidationResult {
  case success(UTF8ExtraInfo)
  case error(toBeReplaced: Range<Int>)
}

extension UTF8ValidationResult: Equatable {}

private struct UTF8ValidationError: Error {}

internal func validateUTF8(_ buf: UnsafeBufferPointer<UInt8>) -> UTF8ValidationResult {
//  if _allASCII(buf) {
//    return .success(UTF8ExtraInfo(isASCII: true))
//  }

  var iter = buf.makeIterator()
  var lastValidIndex = buf.startIndex

  @inline(__always) func guaranteeIn(_ f: (UInt8) -> Bool) throws {
    guard let cu = iter.next() else { throw UTF8ValidationError() }
    guard f(cu) else { throw UTF8ValidationError() }
  }
  @inline(__always) func guaranteeContinuation() throws {
    try guaranteeIn(UTF8.isContinuation)
  }

  func _legacyInvalidLengthCalculation(_ _buffer: (_storage: UInt32, ())) -> Int {
    // function body copied from UTF8.ForwardParser._invalidLength
    if _buffer._storage               & 0b0__1100_0000__1111_0000
                                     == 0b0__1000_0000__1110_0000 {
      // 2-byte prefix of 3-byte sequence. The top 5 bits of the decoded result
      // must be nonzero and not a surrogate
      let top5Bits = _buffer._storage & 0b0__0010_0000__0000_1111
      if top5Bits != 0 && top5Bits   != 0b0__0010_0000__0000_1101 { return 2 }
    }
    else if _buffer._storage                & 0b0__1100_0000__1111_1000
                                           == 0b0__1000_0000__1111_0000
    {
      // Prefix of 4-byte sequence. The top 5 bits of the decoded result
      // must be nonzero and no greater than 0b0__0100_0000
      let top5bits = UInt16(_buffer._storage & 0b0__0011_0000__0000_0111)
      if top5bits != 0 && top5bits.byteSwapped <= 0b0__0000_0100__0000_0000 {
        return _buffer._storage   & 0b0__1100_0000__0000_0000__0000_0000
                                 == 0b0__1000_0000__0000_0000__0000_0000 ? 3 : 2
      }
    }
    return 1
  }

  func _legacyNarrowIllegalRange(buf: Slice<UnsafeBufferPointer<UInt8>>) -> Range<Int> {
    var reversePacked: UInt32 = 0
    if let third = buf.dropFirst(2).first {
      reversePacked |= UInt32(third)
      reversePacked <<= 8
    }
    if let second = buf.dropFirst().first {
      reversePacked |= UInt32(second)
      reversePacked <<= 8
    }
    reversePacked |= UInt32(buf.first!)
    let _buffer: (_storage: UInt32, x: ()) = (reversePacked, ())
    let invalids = _legacyInvalidLengthCalculation(_buffer)
    return buf.startIndex ..< buf.startIndex + invalids
  }

  func findInvalidRange(_ buf: Slice<UnsafeBufferPointer<UInt8>>) -> Range<Int> {
    var endIndex = buf.startIndex
    var iter = buf.makeIterator()
    _ = iter.next()
    while let cu = iter.next(), UTF8.isContinuation(cu) {
      endIndex += 1
    }
    let illegalRange = Range(buf.startIndex...endIndex)
    assert(illegalRange.clamped(to: (buf.startIndex..<buf.endIndex)) == illegalRange,
                 "illegal range out of full range")
    // FIXME: Remove the call to `_legacyNarrowIllegalRange` and return `illegalRange` directly
    return _legacyNarrowIllegalRange(buf: buf[illegalRange])
  }

  do {
    var isASCII = true
    while let cu = iter.next() {
      if UTF8.isASCII(cu) { lastValidIndex &+= 1; continue }
      isASCII = false
      if _slowPath(!_isUTF8MultiByteLeading(cu)) {
        throw UTF8ValidationError()
      }
      switch cu {
      case 0xC2...0xDF:
        try guaranteeContinuation()
        lastValidIndex &+= 2
      case 0xE0:
        try guaranteeIn(_isNotOverlong_E0)
        try guaranteeContinuation()
        lastValidIndex &+= 3
      case 0xE1...0xEC:
        try guaranteeContinuation()
        try guaranteeContinuation()
        lastValidIndex &+= 3
      case 0xED:
        try guaranteeIn(_isNotOverlong_ED)
        try guaranteeContinuation()
        lastValidIndex &+= 3
      case 0xEE...0xEF:
        try guaranteeContinuation()
        try guaranteeContinuation()
        lastValidIndex &+= 3
      case 0xF0:
        try guaranteeIn(_isNotOverlong_F0)
        try guaranteeContinuation()
        try guaranteeContinuation()
        lastValidIndex &+= 4
      case 0xF1...0xF3:
        try guaranteeContinuation()
        try guaranteeContinuation()
        try guaranteeContinuation()
        lastValidIndex &+= 4
      case 0xF4:
        try guaranteeIn(_isNotOverlong_F4)
        try guaranteeContinuation()
        try guaranteeContinuation()
        lastValidIndex &+= 4
      default:
        fatalError()
      }
    }
    return .success(UTF8ExtraInfo(isASCII: isASCII))
  } catch {
    return .error(toBeReplaced: findInvalidRange(buf[lastValidIndex...]))
  }
}

internal func _allASCII(_ input: UnsafeBufferPointer<UInt8>) -> Bool {
  if input.isEmpty { return true }

  // NOTE: Avoiding for-in syntax to avoid bounds checks
  //
  // TODO(String performance): SIMD-ize
  //
  let ptr = input.baseAddress._unsafelyUnwrappedUnchecked
  var i = 0

  let count = input.count
  let stride = MemoryLayout<UInt>.stride
  let address = Int(bitPattern: ptr)

  let wordASCIIMask = UInt(truncatingIfNeeded: 0x8080_8080_8080_8080 as UInt64)
  let byteASCIIMask = UInt8(truncatingIfNeeded: wordASCIIMask)

  while (address &+ i) % stride != 0 && i < count {
    guard ptr[i] & byteASCIIMask == 0 else { return false }
    i &+= 1
  }

  while (i &+ stride) <= count {
    let word: UInt = UnsafePointer(
      bitPattern: address &+ i
    )._unsafelyUnwrappedUnchecked.pointee
    guard word & wordASCIIMask == 0 else { return false }
    i &+= stride
  }

  while i < count {
    guard ptr[i] & byteASCIIMask == 0 else { return false }
    i &+= 1
  }
  return true
}
