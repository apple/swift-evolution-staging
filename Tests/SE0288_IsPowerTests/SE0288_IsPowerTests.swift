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

import XCTest
@testable import SE0288_IsPower

final class SE0288_IsPowerTests: XCTestCase {
  func testDemo() {
    let x: Int = Int.random(in: 0000..<0288)
    XCTAssertTrue(1.isPower(of: x), "x^0 == 1")

    let y: UInt = 1000
    XCTAssertTrue(y.isPower(of: 10), "10^3 == 1000")

    XCTAssertFalse((-1).isPower(of: 1), "-1 is not any power of 1")

    XCTAssertTrue((-32).isPower(of: -2), "(-2)^5 == -32")
  }

  func testIntegerTypes() {
    func doTest<T: FixedWidthInteger>(type: T.Type) {
      func testIntegers(in range: ClosedRange<T>, base: T) {
        // Collect all powers of base covering the whole range
        var powers = Set<T>([1, base].filter{ range.contains($0) });
        if base.magnitude >= 2 {
            var x = base
            let bound = max(range.lowerBound.magnitude,
                            range.upperBound.magnitude)
            while x.magnitude <= bound {
              let (product, overflow) = x.multipliedReportingOverflow(by: base)
              guard !overflow else { break }
              x = product
              if range.contains(x) {
                powers.insert(x)
              }
            }
        }
        // Check every value within range
        for value in range {
            let expected = powers.contains(value)
            let actual = value.isPower(of: base)
            XCTAssertEqual(expected, actual,
                        "(\(value)).isPower(of: \(base)) should be \(expected)")
        }
      }

      let range = T(clamping: Int8.min)...T(clamping: Int8.max)
      let bases = Set([-3, -2, -1, 0, 1, 2, 5, 8, 10, 11].map{ T(clamping: $0) })
      for base in bases {
        testIntegers(in: range, base: base)
      }

      XCTAssertFalse(T.max.isPower(of: 2))
      XCTAssertFalse(T.min.isPower(of: 2))
      if T.isSigned {
        XCTAssertTrue(T.min.isPower(of: -2))
        XCTAssertTrue(((1 as T) << (T.bitWidth - 2)).isPower(of: 2))
      } else {
        XCTAssertTrue(((1 as T) << (T.bitWidth - 1)).isPower(of: 2))
      }
    }

    doTest(type: Int.self)
    doTest(type: Int8.self)
    doTest(type: Int16.self)
    doTest(type: Int32.self)
    doTest(type: Int64.self)
    doTest(type: UInt.self)
    doTest(type: UInt8.self)
    doTest(type: UInt16.self)
    doTest(type: UInt32.self)
    doTest(type: UInt64.self)
  }
}
