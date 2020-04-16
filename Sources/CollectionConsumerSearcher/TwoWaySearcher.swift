/// A collection searcher that implements the two-way string-matching algorithm.
///
/// http://monge.univ-mlv.fr/~mac/Articles-PDF/CP-1991-jacm.pdf
internal struct _TwoWayAlgorithmSearcher<C, N>
  where C: BidirectionalCollection, N: BidirectionalCollection,
    C.Element: Comparable, C.Element == N.Element
{
  var needle: N
  var parameters: Parameters

  init(_ needle: N) {
    self.needle = needle
    self.parameters = Parameters(factoring: needle)
  }
}

extension _TwoWayAlgorithmSearcher {
  /// The initial parameters for the two-way algorithm, based on selecting a critical
  /// factorization of the needle into a prefix and suffix.
  struct Parameters {
    /// The end of the needle prefix.
    var endLeft: N.Index

    /// The length of the needle prefix.
    var endLeftOffset: Int

    /// The period of the needle.
    var period: Int

    /// The length of the needle.
    var count: Int

    /// Whether the algorithm should use memorization to reduce the number of comparisons.
    ///
    /// This is only possible when the prefix matches a particular part of the suffix (it 
    /// must be a suffix of a `period`-length prefix of the suffix).
    var useMemorization: Bool

    /// When using memorization, where to stop when checking for a match in the left part
    /// of the factored needle.
    var leftStop: N.Index
    
    init(factoring x: N) {
      let (endLeft, period, count) = Self.criticalFactorization(x)
      self.endLeft = endLeft
      self.endLeftOffset = x.distance(from: x.startIndex, to: endLeft)
      self.period = period
      self.count = count
      self.leftStop = x.startIndex 

      let left = x[..<endLeft]
      let right = x[endLeft...].prefix(period).suffix(endLeftOffset)
      self.useMemorization = endLeftOffset < count / 2
        && left.elementsEqual(right)

      if !useMemorization {
        self.period = max(endLeftOffset, count - endLeftOffset)
      } else {
        self.leftStop = x.index(x.startIndex, offsetBy: count - period - 1)
      }
    }

    static func criticalFactorization(_ c: N) -> (index: N.Index, period: Int, count: Int) {
      let (index1, period1, count) = maximalSuffix(of: c, ascending: true)
      let (index2, period2, _) = maximalSuffix(of: c, ascending: false)
      return index1 >= index2
        ? (index1, period1, count)
        : (index2, period2, count)
    }

    static func maximalSuffix(of c: N, ascending: Bool) -> (i: N.Index, p: Int, count: Int) {
      if c.isEmpty { return (c.startIndex, 0, 0) }

      var count = 1
      var i = c.startIndex                    // actually 'i + k'
      var j = c.index(after: i)               // actually 'j + k'
      var k = 0                               // zero-based instead of 1-based
      var p = 1

      while j < c.endIndex {
        let a = c[i]
        let b = c[j]
        
        if a == b {
          if k == p - 1 {
            c.formIndex(&i, offsetBy: -k)
            c.formIndex(after: &j)
            count += 1
            k = 0
          } else {
            c.formIndex(after: &i)
            c.formIndex(after: &j)
            count += 1
            k += 1
          }
        } else if (a < b) == ascending {
          c.formIndex(&i, offsetBy: -k)
          c.formIndex(after: &j)
          count += 1
          k = 0
          p = c.distance(from: i, to: j)
        } else {
          i = c.index(j, offsetBy: -k)
          j = c.index(after: i)
          count += 1 - k
          k = 0
          p = 1
        }
      }

      return (c.index(i, offsetBy: -k), p, count)
    }
  }
}

extension _TwoWayAlgorithmSearcher: CollectionSearcher {
  /// State information about the haystack to search.
  struct State {
    /// The last possible starting index for a match.
    var searchEnd: C.Index

    /// The current position in the haystack.
    var haystackCurrent: C.Index

    /// The state of memorization of seeing a prefix in the haystack.
    var memory = -1
    
    init(for haystack: C, with x: N, parameters: Parameters) {
      let leftEndOffset = x.distance(from: x.startIndex, to: parameters.endLeft)
      self.searchEnd = haystack.index(haystack.endIndex, offsetBy: -parameters.count + parameters.endLeftOffset)
      self.haystackCurrent = haystack.index(haystack.startIndex, offsetBy: leftEndOffset)
    }
  }

  func preprocess(_ c: C) -> State {
    return State(for: c, with: needle, parameters: parameters)
  }

  func search(_ c: C, from start: C.Index, _ state: inout State) -> Range<C.Index>? {
    guard !needle.isEmpty,
      start <= state.searchEnd,
      let current = c.index(start, offsetBy: parameters.endLeftOffset, limitedBy: state.searchEnd)
      else { return nil }
    
    state.haystackCurrent = current
    
    return parameters.useMemorization
      ? twoWayMemorizationIncremental(in: c, state: &state)
      : twoWayIncremental(in: c, state: &state)
  }
  
  /// Returns the range of the next match for `needle` in `c`, with the given state and parameters.
  ///
  /// This method corresponds to the 'positions-bis' algorithm in CP.
  func twoWayIncremental(in c: C, state s: inout State) -> Range<C.Index>? {
    assert(parameters.useMemorization == false)

    while s.haystackCurrent <= s.searchEnd {
      var needleCursor = parameters.endLeft   // Moving index in needle
      var haystackCursor = s.haystackCurrent  // Moving index in haystack
      
      // Try to match the suffix.
      while needleCursor < needle.endIndex && needle[needleCursor] == c[haystackCursor] {
        needle.formIndex(after: &needleCursor)
        c.formIndex(after: &haystackCursor)
      }

      if needleCursor < needle.endIndex {
        // The suffix didn't match, so advance past the mismatch.
        s.haystackCurrent = c.index(after: haystackCursor)
      } else {
        // The suffix matched. Try to match the prefix below.
        
        defer {
          // We can exit the loop by either having a mismatch in the prefix or by matching
          // fully and returning the matched range. In either case, we advance by the period
          // to prepare for the next search.
          _ = c.formIndex(&s.haystackCurrent, offsetBy: parameters.period, limitedBy: c.endIndex)
        }
        
        // If the prefix is empty, we've completed a match.
        if parameters.endLeft == needle.startIndex {
          return s.haystackCurrent ..< haystackCursor
        }

        // Start at the end of the prefix and work backward to the start of the match.
        needleCursor = needle.index(before: parameters.endLeft)
        var haystackReverseCursor = c.index(before: s.haystackCurrent)

        while needleCursor >= needle.startIndex && needle[needleCursor] == c[haystackReverseCursor] {
          if needleCursor == needle.startIndex {
            return haystackReverseCursor ..< haystackCursor
          }
          needle.formIndex(before: &needleCursor)
          c.formIndex(before: &haystackReverseCursor)
        }
      }
    }

    return nil
  }
  
  /// Returns the range of the next match for `needle` in `c`, with the given state and parameters.
  ///
  /// This method corresponds to the 'positions' algorithm in CP.
  func twoWayMemorizationIncremental(in c: C, state s: inout State) -> Range<C.Index>? {
    assert(parameters.useMemorization == true)

    var needleCursor: N.Index         // Moving index in needle
    var haystackCursor: C.Index       // Moving index in haystack

    s.memory = 0
    var needleLowerBound = needle.startIndex

    while s.haystackCurrent <= s.searchEnd {
      // If we've memorized a matched portion of the prefix, we can start searching later
      // in the suffix.
      if s.memory <= parameters.endLeftOffset + 1 {
        needleCursor = parameters.endLeft
        haystackCursor = s.haystackCurrent
      } else {
        let additionalOffset = s.memory - parameters.endLeftOffset - 1
        needleCursor = needle.index(parameters.endLeft, offsetBy: additionalOffset, limitedBy: needle.endIndex) ?? needle.endIndex
        haystackCursor = c.index(s.haystackCurrent, offsetBy: additionalOffset, limitedBy: c.endIndex) ?? c.endIndex
      }
      
      // Try to match the suffix.
      while needleCursor < needle.endIndex && needle[needleCursor] == c[haystackCursor] {
        needle.formIndex(after: &needleCursor)
        c.formIndex(after: &haystackCursor)
      }

      if needleCursor < needle.endIndex {
        // The suffix didn't match, so advance past the mismatch and reset the memorization.
        s.haystackCurrent = c.index(after: haystackCursor)
        s.memory = 0
        needleLowerBound = needle.startIndex
      } else {
        // The suffix matched. Try to match the prefix below.

        defer {
          // We can exit the loop by either having a mismatch in the prefix or by matching
          // fully and returning the matched range. In either case, we advance by the period
          // to prepare for the next search and update the memorization of the prefix.
          _ = c.formIndex(&s.haystackCurrent, offsetBy: parameters.period, limitedBy: c.endIndex)
          s.memory = parameters.count - parameters.period - 1
          needleLowerBound = parameters.leftStop
        }
        
        // If the prefix is empty, we've completed a match.
        if parameters.endLeft == needle.startIndex {
          return s.haystackCurrent ..< haystackCursor
        }

        // Start at the end of the prefix and work backward to the start of the match.
        needleCursor = needle.index(before: parameters.endLeft)
        var haystackReverseCursor = c.index(before: s.haystackCurrent)

        while needleCursor >= needle.startIndex && needle[needleCursor] == c[haystackReverseCursor] {
          if needleCursor <= needleLowerBound {
            let memoryOffset = needle.distance(from: needleCursor, to: needle.startIndex)
            return c.index(haystackReverseCursor, offsetBy: memoryOffset) ..< haystackCursor
          }
          needle.formIndex(before: &needleCursor)
          c.formIndex(before: &haystackReverseCursor)
        }
      }
    }

    return nil
  }
}
