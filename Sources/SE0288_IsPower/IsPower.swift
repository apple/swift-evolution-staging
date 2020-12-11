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

extension BinaryInteger {
  /// Returns `true` if this value is a power of the given base, and `false`
  /// otherwise.
  ///
  /// For two integers *a* and *b*, *a* is a power of *b* if *a* is equal to
  /// any repeated multiplication of *b*. For example:
  ///
  /// * `16.isPower(of: 2)` is `true`, because `16 == (2 * 2 * 2 * 2)`
  /// * `(-27).isPower(of: -3)` is `true`, because `-27 == (-3 * -3 * -3)`
  ///
  /// Note that one is a power of anything, because any number to the zero
  /// power is considered an empty product, which equals one.
  ///
  /// For the corner case where base is zero, `x.isPower(of: 0)` is `true` if
  /// `x` is either zero or one, and `false` otherwise.
  ///
  /// - Parameter base: The base value to test.
  @_alwaysEmitIntoClient
  public func isPower<Base: BinaryInteger>(of base: Base) -> Bool {
    // Fast path when base is one of the common cases.
    if base == 2 { return self._isPowerOfTwo }
    if base == 10 { return self._isPowerOfTen }
    if base._isPowerOfTwo { return self._isPowerOf(powerOfTwo: base) }
    // Slow path for other bases.
    return self._slowIsPower(of: base)
  }

  /// Returns `true` iff `self` is a power of two.
  ///
  /// This serves as a fast path for `isPower(of:)` when the input base is two.
  @_alwaysEmitIntoClient
  internal var _isPowerOfTwo: Bool {
    let words = self.words
    guard !words.isEmpty else { return false }

    // If the value is represented in a single word, perform the classic check.
    if words.count == 1 {
      return self > 0 && self & (self - 1) == 0
    }

    // Return false if it is negative.  Here we only need to check the most
    // significant word (i.e. the last element of `words`).
    if Self.isSigned && Int(bitPattern: words.last!) < 0 {
      return false
    }

    // Check if there is exactly one non-zero word and it is a power of two.
    var found = false
    for word in words {
      if word != 0 {
        if found || word & (word - 1) != 0 { return false }
        found = true
      }
    }
    return found
  }

  /// Returns `true` iff `self` is a power of the given `base`, which itself is
  /// a power of two.
  ///
  /// This serves as a fast path for `isPower(of:)` when the input base itself
  /// is a power of two.
  @_alwaysEmitIntoClient
  internal func _isPowerOf<Base: BinaryInteger>(powerOfTwo base: Base) -> Bool {
    precondition(base._isPowerOfTwo)
    guard self._isPowerOfTwo else { return false }
    return self.trailingZeroBitCount.isMultiple(of: base.trailingZeroBitCount)
  }

  /// Returns `true` iff `self` is a power of ten.
  ///
  /// This serves as a fast path for `isPower(of:)` when the input base is ten.
  @_alwaysEmitIntoClient
  internal var _isPowerOfTen: Bool {
    let exponent = self.trailingZeroBitCount
    switch exponent {
    case 0:  return self == 1 as UInt8
    case 1:  return self == 10 as UInt8
    case 2:  return self == 100 as UInt8
    case 3:  return self == 1000 as UInt16
    case 4:  return self == 10000 as UInt16
    case 5:  return self == 100000 as UInt32
    case 6:  return self == 1000000 as UInt32
    case 7:  return self == 10000000 as UInt32
    case 8:  return self == 100000000 as UInt32
    case 9:  return self == 1000000000 as UInt32
    case 10: return self == 10000000000 as UInt64
    case 11: return self == 100000000000 as UInt64
    case 12: return self == 1000000000000 as UInt64
    case 13: return self == 10000000000000 as UInt64
    case 14: return self == 100000000000000 as UInt64
    case 15: return self == 1000000000000000 as UInt64
    case 16: return self == 10000000000000000 as UInt64
    case 17: return self == 100000000000000000 as UInt64
    case 18: return self == 1000000000000000000 as UInt64
    case 19: return self == 10000000000000000000 as UInt64
    default:
      // If this is 64-bit or less we can't have a higher power of 10
      if self.bitWidth <= 64 { return false }

      // Quickly check if parts of the bit pattern fits the power of 10.
      //
      // 10^0                                     1
      // 10^1                                  1_01_0
      // 10^2                               1_10_01_00
      // 10^3                             111_11_01_000
      // 10^4                          100111_00_01_0000
      // 10^5                        11000011_01_01_00000
      // 10^6                      1111010000_10_01_000000
      // 10^7                   1001100010010_11_01_0000000
      // 10^8                 101111101011110_00_01_00000000
      // 10^9               11101110011010110_01_01_000000000
      // 10^10           10010101000000101111_10_01_0000000000
      // ...
      // Column 1 is some "gibberish", which cannot be checked easily
      // Column 2 is always the last two bits of the exponent
      // Column 3 is always 01
      // Column 4 is the trailing zeros, in equal number to the exponent value
      //
      // We check if Column 2 matches the last two bits of the exponent and
      // Column 3 matches 0b01.
      guard (self >> exponent)._lowWord & 0b1111 ==
        ((exponent << 2) | 0b01) & 0b1111 else { return false }

      // Now time for the slow path.
      return self._slowIsPower(of: 10)
    }
  }

  /// Returns `true` iff `self` is a power of the given `base`.
  ///
  /// This serves as the slow path for `isPower(of:)` when `Self` and `Base`
  /// are different types.
  @_alwaysEmitIntoClient
  internal func _slowIsPower<Base: BinaryInteger>(of base: Base) -> Bool {
    if let baseAsSelf = Self(exactly: base) {
      return _slowIsPower(of: baseAsSelf)
    } else if let selfAsBase = Base(exactly: self) {
      return selfAsBase._slowIsPower(of: base)
    } else {
      preconditionFailure("isPower(:of) cannot be applied to " +
        "self (\(self) of type '\(Self.self)') and " +
        "base (\(base) of type '\(Base.self)'), " +
        "because neither '\(Self.self)' nor '\(Base.self)' " +
        "can represent the other value.")
    }
  }

  /// Returns `true` iff `self` is a power of the given `base`.
  ///
  /// This serves as the slow path for `isPower(of:)`; it is based on a generic
  /// implementation that works for any input `base`.
  @_alwaysEmitIntoClient
  internal func _slowIsPower(of base: Self) -> Bool {
    // If self is 1 (i.e. any base to the zero power), return true.
    if self == 1 { return true }

    // Here if base is 0, 1 or -1, return true iff self equals base.
    if base.magnitude <= 1 { return self == base }

    // At this point, we have base.magnitude >= 2. We are going to repeatedly
    // perform multiplication by a factor of base, and check if it can equal
    // self. Such algorithm should be bounded to ensure termination.
    //
    // Calculate the bound, and return false when self is not multiple of base.
    let (bound, remainder) = self.quotientAndRemainder(dividingBy: base)
    guard remainder == 0 else { return false }

    // Return true if the product eventually hits bound. Because if bound is
    // power of base, then self (i.e. bound * base) must also be power of base.
    var x: Self = 1
    while x.magnitude < bound.magnitude { x *= base }
    return x == bound
  }
}
