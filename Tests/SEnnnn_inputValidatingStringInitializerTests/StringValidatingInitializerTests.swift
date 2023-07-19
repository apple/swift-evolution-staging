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
import SE0000inputValidatingStringInitializers

let s1 = "Long string containing the characters é, ß, 🦆, and 👨‍👧‍👦."
let s2 = "Long ascii string with no accented characters (obviously)."

final class string_validatingTests: XCTestCase {
  func testExample() throws {
    // XCTest Documentation
    // https://developer.apple.com/documentation/xctest
    
    // Defining Test Cases and Test Methods
    // https://developer.apple.com/documentation/xctest/defining_test_cases_and_test_methods
  }
  
  func testValidatingUTF8() throws {
    let i1 = Array(s1.utf8)
    let i2 = Array(s2.utf8)
    let i3 = {
      var modified = i1
      let index = modified.lastIndex(of: 240)
      XCTAssertNotNil(index)
      index.map { modified[$0] = 0 }
      return modified
    }()

    XCTAssertEqual(String(validating: i1, as: UTF8.self), s1)
    XCTAssertEqual(String(validating: i2, as: UTF8.self), s2)
    XCTAssertNil(String(validating: i3, as: UTF8.self))

    XCTAssertEqual(String(validating: AnyCollection(i1), as: UTF8.self), s1)
    XCTAssertEqual(String(validating: AnyCollection(i2), as: UTF8.self), s2)
    XCTAssertNil(String(validating: AnyCollection(i3), as: UTF8.self))
  }

  func testValidatingUTF8CChar() throws {
    let i1 = s1.utf8.map(CChar.init(bitPattern:))
    let i2 = s2.utf8.map(CChar.init(bitPattern:))
    let i3 = {
      var modified = i1
      let index = modified.lastIndex(of: CChar(bitPattern: 240))
      XCTAssertNotNil(index)
      index.map { modified[$0] = 0 }
      return modified
    }()

    i1.withUnsafeBufferPointer {
      XCTAssertEqual(String(validatingFromUTF8: $0), s1)
    }
    i2.withUnsafeBufferPointer {
      XCTAssertEqual(String(validatingFromUTF8: $0), s2)
    }
    i3.withUnsafeBufferPointer {
      XCTAssertNil(String(validatingFromUTF8: $0))
    }
  }

  func testValidatingASCII() throws {
    let i1 = Array(s1.utf8)
    let i2 = Array(s2.utf8)

    XCTAssertNil(String(validating: i1, as: Unicode.ASCII.self))
    XCTAssertEqual(String(validating: i2, as: Unicode.ASCII.self), s2)

    XCTAssertNil(String(validating: AnyCollection(i1), as: Unicode.ASCII.self))
    XCTAssertEqual(String(validating: AnySequence(i2), as: Unicode.ASCII.self), s2)
  }

  func testValidatingUTF16() throws {
    let i1 = Array(s1.utf16)
    let i2 = Array(s2.utf16)
    let i3 = {
      var modified = i1
      let index = modified.lastIndex(of: 32)
      XCTAssertNotNil(index)
      index.map { modified[$0] = 0xd801 }
      return modified
    }()

    XCTAssertEqual(String(validating: i1, as: UTF16.self), s1)
    XCTAssertEqual(String(validating: i2, as: UTF16.self), s2)
    XCTAssertNil(String(validating: i3, as: UTF16.self))

    XCTAssertEqual(String(validating: AnySequence(i1), as: UTF16.self), s1)
    XCTAssertEqual(String(validating: AnySequence(i2), as: UTF16.self), s2)
    XCTAssertNil(String(validating: AnyCollection(i3), as: UTF16.self))
  }

  func testValidatingUTF32() throws {
    let i1 = s1.unicodeScalars.map(\.value)
    let i2 = s2.unicodeScalars.map(\.value)
    let i3 = {
      var modified = i1
      let index = modified.lastIndex(of: .init(bitPattern: 32))
      XCTAssertNotNil(index)
      index.map { modified[$0] = .max }
      return modified
    }()

    XCTAssertEqual(String(validating: i1, as: UTF32.self), s1)
    XCTAssertEqual(String(validating: i2, as: UTF32.self), s2)
    XCTAssertNil(String(validating: i3, as: UTF32.self))

    XCTAssertEqual(String(validating: AnySequence(i1), as: UTF32.self), s1)
    XCTAssertEqual(String(validating: AnySequence(i2), as: UTF32.self), s2)
    XCTAssertNil(String(validating: AnyCollection(i3), as: UTF32.self))
  }
}
