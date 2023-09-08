//===--- StringValidatingInitializers.swift -------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Swift

extension String {

  /// Creates a new `String` by copying and validating the sequence of
  /// code units passed in, according to the specified encoding.
  ///
  /// This initializer does not try to repair ill-formed code unit sequences.
  /// If any are found, the result of the initializer is `nil`.
  ///
  /// The following example calls this initializer with the contents of two
  /// different arrays---first with a well-formed UTF-8 code unit sequence and
  /// then with an ill-formed UTF-16 code unit sequence.
  ///
  ///     let validUTF8: [UInt8] = [67, 97, 0, 102, 195, 169]
  ///     let valid = String(validating: validUTF8, as: UTF8.self)
  ///     print(valid)
  ///     // Prints "Optional("Café")"
  ///
  ///     let invalidUTF16: [UInt16] = [0x41, 0x42, 0xd801]
  ///     let invalid = String(validating: invalidUTF16, as: UTF16.self)
  ///     print(invalid)
  ///     // Prints "nil"
  ///
  /// - Parameters:
  ///   - codeUnits: A sequence of code units that encode a `String`
  ///   - encoding: A conformer to `Unicode.Encoding` to be used
  ///               to decode `codeUnits`.
  @inlinable
  public init?<Encoding: Unicode.Encoding>(
    validating codeUnits: some Sequence<Encoding.CodeUnit>,
    as encoding: Encoding.Type
  ) {
    let newString: String?? = codeUnits.withContiguousStorageIfAvailable {
      String(_validating: $0, as: Encoding.self)
    }
    if let newString {
      guard let newString else { return nil }
      self = newString
      return
    }
    
    // slow-path
    var transcoded: [UTF8.CodeUnit] = []
    transcoded.reserveCapacity(codeUnits.underestimatedCount)
    var isASCII = true
    let error = transcode(
      codeUnits.makeIterator(),
      from: Encoding.self,
      to: UTF8.self,
      stoppingOnError: true,
      into: {
        uint8 in
        transcoded.append(uint8)
        if isASCII && (uint8 & 0x80) == 0x80 { isASCII = false }
      }
    )
    if error { return nil }
    self = transcoded.withUnsafeBufferPointer{
      String._uncheckedFromUTF8($0, asciiPreScanResult: isASCII)
    }
  }

  @usableFromInline
  internal init?<Encoding: Unicode.Encoding>(
    _validating input: UnsafeBufferPointer<Encoding.CodeUnit>,
    as encoding: Encoding.Type
  ) {
    //TODO: Validate and copy in chunks of up to some cachable amount of memory.
  fast: if encoding.CodeUnit.self == UInt8.self {
      let bytes = _identityCast(input, to: UnsafeBufferPointer<UInt8>.self)
      let isASCII: Bool
      if encoding.self == UTF8.self {
        guard case .success(let info) = validateUTF8(bytes) else { return nil }
        isASCII = info.isASCII
      } else if encoding.self == Unicode.ASCII.self {
        guard _allASCII(bytes) else { return nil }
        isASCII = true
      } else {
        break fast
      }
      self = String._uncheckedFromUTF8(bytes, asciiPreScanResult: isASCII)
      return
    }
    
    // there must be a better way to get this multiplier
    let multiplier = if encoding.self == UTF16.self { 3 } else { 4 }

    // slow-path
    let newString = withUnsafeTemporaryAllocation(
      of: UInt8.self, capacity: input.count * multiplier
    ) {
      output -> String? in
      var isASCII = true
      var index = output.startIndex
      let error = transcode(
        input.makeIterator(),
        from: encoding.self,
        to: UTF8.self,
        stoppingOnError: true,
        into: {
          uint8 in
          output[index] = uint8
          output.formIndex(after: &index)
          if isASCII && (uint8 & 0x80) == 0x80 { isASCII = false }
        }
      )
      if error { return nil }
      let bytes = UnsafeBufferPointer(start: output.baseAddress, count: index)
      return String._uncheckedFromUTF8(bytes, asciiPreScanResult: isASCII)
    }
    guard let newString else { return nil }
    self = newString
  }
}

extension String {

  /// Creates a new `String` by copying and validating the sequence of
  /// `Int8` passed in, according to the specified encoding.
  ///
  /// This initializer does not try to repair ill-formed code unit sequences.
  /// If any are found, the result of the initializer is `nil`.
  ///
  /// The following example calls this initializer with the contents of two
  /// different arrays---first with a well-formed UTF-8 code unit sequence and
  /// then with an ill-formed ASCII code unit sequence.
  ///
  ///     let validUTF8: [Int8] = [67, 97, 0, 102, -61, -87]
  ///     let valid = String(validating: validUTF8, as: UTF8.self)
  ///     print(valid)
  ///     // Prints "Optional("Café")"
  ///
  ///     let invalidASCII: [Int8] = [67, 97, -5]
  ///     let invalid = String(validating: invalidASCII, as: Unicode.ASCII.self)
  ///     print(invalid)
  ///     // Prints "nil"
  ///
  /// - Parameters:
  ///   - codeUnits: A sequence of code units that encode a `String`
  ///   - encoding: A conformer to `Unicode.Encoding` that can decode
  ///               `codeUnits` as `UInt8`
  @inlinable
  public init?<Encoding>(
    validating codeUnits: some Sequence<Int8>,
    as encoding: Encoding.Type
  ) where Encoding: Unicode.Encoding, Encoding.CodeUnit == UInt8 {
    let newString: String?? = codeUnits.withContiguousStorageIfAvailable {
      $0.withMemoryRebound(to: UInt8.self) {
        String(_validating: $0, as: Encoding.self)
      }
    }
    if let newString {
      guard let newString else { return nil }
      self = newString
      return
    }

    // slow-path
    let rebound = codeUnits.lazy.map(UInt8.init(bitPattern:))
    if let string = String(validating: rebound, as: Encoding.self) {
      self = string
      return
    }
    return nil
  }
}

extension String {
  /// Creates a new string by copying and validating the null-terminated UTF-8
  /// data referenced by the given pointer.
  ///
  /// This initializer does not try to repair ill-formed UTF-8 code unit
  /// sequences. If any are found, the result of the initializer is `nil`.
  ///
  /// The following example calls this initializer with pointers to the
  /// contents of two different `CChar` arrays---first with well-formed
  /// UTF-8 code unit sequences and the second with an ill-formed sequence at
  /// the end.
  ///
  ///     let validUTF8: [CChar] = [67, 97, 102, -61, -87, 0]
  ///     validUTF8.withUnsafeBufferPointer { ptr in
  ///         let s = String(validatingUTF8: ptr.baseAddress!)
  ///         print(s)
  ///     }
  ///     // Prints "Optional("Café")"
  ///
  ///     let invalidUTF8: [CChar] = [67, 97, 102, -61, 0]
  ///     invalidUTF8.withUnsafeBufferPointer { ptr in
  ///         let s = String(validatingUTF8: ptr.baseAddress!)
  ///         print(s)
  ///     }
  ///     // Prints "nil"
  ///
  /// - Parameter cString: A pointer to a null-terminated UTF-8 code sequence.
  public init?(
    validatingCString nullTerminatedCodeUnits: UnsafePointer<CChar>
  ) {
    guard let s = String(validatingUTF8: nullTerminatedCodeUnits)
    else { return nil }
    self = s
  }
}
