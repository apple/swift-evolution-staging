//===--- StringValidatingInitializerSnippets.swift ------------------------===//
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

import XCTest
import SE0405inputValidatingStringInitializers

final class StringValidationSnippets: XCTestCase {
  
  func testValidatingSomeSequenceAsEncoding() {
    let validUTF8: [UInt8] = [67, 97, 0, 102, 195, 169]
    let valid = String(validating: validUTF8, as: UTF8.self)
    // print(valid)
    // Prints "Optional("Café")"
    XCTAssertEqual(valid, Optional("Ca\0fé"))

    let invalidUTF16: [UInt16] = [0x41, 0x42, 0xd801]
    let invalid = String(validating: invalidUTF16, as: UTF16.self)
    // print(invalid)
    // Prints "nil"
    XCTAssertNil(invalid)
  }

  func testValidatingSomeSequenceOfInt8AsEncoding() {
    let validUTF8: [Int8] = [67, 97, 0, 102, -61, -87]
    let valid = String(validating: validUTF8, as: UTF8.self)
    // print(valid)
    // Prints "Optional("Café")"
    XCTAssertEqual(valid, Optional("Ca\0fé"))

    let invalidASCII: [Int8] = [67, 97, -5]
    let invalid = String(validating: invalidASCII, as: Unicode.ASCII.self)
    // print(invalid)
    // Prints "nil"
    XCTAssertNil(invalid)
  }

  func testValidatingCStringUTF8() {
    let validUTF8: [CChar] = [67, 97, 102, -61, -87, 0]
    validUTF8.withUnsafeBufferPointer { ptr in
      let s = String(validatingCString: ptr.baseAddress!)
      // print(s)
      // Prints "Optional("Café")"
      XCTAssertEqual(s, Optional("Café"))
    }

    let invalidUTF8: [CChar] = [67, 97, 102, -61, 0]
    invalidUTF8.withUnsafeBufferPointer { ptr in
      let s = String(validatingCString: ptr.baseAddress!)
      // print(s)
      // Prints "nil"
      XCTAssertNil(s)
    }
  }
}
