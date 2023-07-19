//===--- StringValidatingInitializerTestss.swift --------------------------===//
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
import SEnnnn_inputValidatingStringInitializers

final class StringValidationSnippets: XCTestCase {
  
  func testValidatingSomeSequenceAsEncoding() {
    let validUTF8: [UInt8] = [67, 97, 102, 195, 169]
    let valid = String(validating: validUTF8, as: UTF8.self)
    // print(valid)
    // Prints "Optional("Café")"
    XCTAssertEqual(valid, Optional("Café"))
    
    let invalidUTF16: [UInt16] = [0x41, 0x42, 0xd801]
    let invalid = String(validating: invalidUTF16, as: UTF16.self)
    // print(invalid)
    // Prints "nil"
    XCTAssertNil(invalid)
  }
  
  func testValidatingUInt8ArrayAsUTF8() {
    let validUTF8: [UInt8] = [67, 97, 102, 195, 169]
    let valid = String.init(validatingFromUTF8: validUTF8)
    // print(valid)
    // Prints "Optional("Café")"
    XCTAssertEqual(valid, Optional("Café"))
    
    let invalidUTF8: [UInt8] = [67, 195, 0]
    let invalid = String.init(validatingFromUTF8: invalidUTF8)
    // print(invalid)
    // Prints "nil"
    XCTAssertNil(invalid)
  }
  
  func testValidatingBufferOfCCharAsUTF8() {
    let validUTF8: [CChar] = [67, 97, 102, -61, -87]
    let valid = validUTF8.withUnsafeBufferPointer {
      String.init(validatingFromUTF8: $0)
    }
    // print(valid)
    // Prints "Optional("Café")"
    XCTAssertEqual(valid, Optional("Café"))
    
    let invalidUTF8: [CChar] = [67, -61, 0]
    let invalid = invalidUTF8.withUnsafeBufferPointer {
      String.init(validatingFromUTF8: $0)
    }
    // print(invalid)
    // Prints "nil"
    XCTAssertNil(invalid)
  }
  
  func testValidatingUInt16ArrayAsUTF16() {
    let validUTF16: [UInt16] = [67, 97, 102, 233]
    let valid = String(validatingFromUTF16: validUTF16)
    // print(valid)
    // Prints "Optional("Café")"
    XCTAssertEqual(valid, Optional("Café"))

    let invalidUTF16: [UInt16] = [0x41, 0x42, 0xd801]
    let invalid = String(validatingFromUTF16: invalidUTF16)
    // print(invalid)
    // Prints "nil"
    XCTAssertNil(invalid)
  }

  func testValidatingUInt32ArrayAsUTF32() {
    let validUTF32: [UInt32] = [67, 97, 102, 233]
    let valid = String(validatingFromUTF32: validUTF32)
    // print(valid)
    // Prints "Optional("Café")"
    XCTAssertEqual(valid, Optional("Café"))

    let invalidUTF32: [UInt32] = [0x41, 0x42, 0xd801]
    let invalid = String(validatingFromUTF32: invalidUTF32)
    // print(invalid)
    // Prints "nil"
    XCTAssertNil(invalid)
  }
}
