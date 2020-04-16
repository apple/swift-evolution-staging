/// A collection searcher that uses the Z-array algorithm to find matching
/// subsequences.
internal struct _ZAlgorithmSearcher<C, N>
  where C: BidirectionalCollection, N: BidirectionalCollection,
    C.Element: Equatable, C.Element == N.Element
{
  var needle: N
  var initialZArray: [Int]

  var needleCount: Int {
    initialZArray.count - 1
  }

  init(_ needle: N) {
    self.needle = needle
    self.initialZArray = _ZAlgorithmSearcher.buildInitialZArray(needle)
  }
  
  /// Builds the z-array for the needle to search for. This initial z-array can
  /// (in theory) be reused for searching across multiple collections.
  static func buildInitialZArray(_ s: N) -> [Int] {
    var z = [-1]
    var L = 0
    var R = L
    var Ri = s.startIndex     // Tracks position R in s
    var LRi = s.startIndex    // Tracks position R - L in s
    
    var i = z.count
    while i < s.count {
      defer { i += 1 }
      
      if i <= R {
        let k = z[i - L]
        if k < R - i + 1 {
          z.append(k)
          continue
        }
      }

      s.formIndex(&Ri, offsetBy: i - R)
      LRi = s.startIndex
      R = i
      L = i
      while Ri < s.endIndex && s[LRi] == s[Ri] {
        R += 1
        s.formIndex(after: &Ri)
        s.formIndex(after: &LRi)
      }
      z.append(R - L)
      R -= 1
      s.formIndex(before: &Ri)
    }
    
    z.append(0)
    return z
  }
}

extension _ZAlgorithmSearcher: CollectionSearcher {
  typealias State = [Int]

  func preprocess(_ haystack: C) -> State {
    initialZArray
  }
  
  /// Search for a match in `c[start...]`, building the z-array in the process.
  ///
  /// The z-array used here represents the matching prefix distances for a non-existent 
  /// collection that would concatenate `needle`, a "missing" element, and `c`.
  func search(_ c: C, from start: C.Index, _ z: inout State) -> Range<C.Index>? {
    let startOffset = needleCount + 1 + c.distance(from: c.startIndex, to: start)

    var high: Int
    var highIndex: C.Index      // Tracks position `high` in `c`
    
    // Stage 1: Determine where to start searching -- the minimum of the z-array
    // that has previously been built or the starting point of the search.

    if startOffset >= z.count {
      // We need to continue building the z-array to look for a match
      high = z.count - 1
      highIndex = c.index(c.startIndex, offsetBy: z.count - needleCount - 2)
    } else {
      // We've built the z-array past `start`, so first look for a match in
      // what we've already built.
      high = startOffset
      highIndex = start
      while high < z.count {
        if z[high] == needleCount {
          return highIndex ..< c.index(highIndex, offsetBy: needleCount)
        }
        high += 1
        c.formIndex(after: &highIndex)
      }
      high -= 1
      c.formIndex(before: &highIndex)
    }

    var low = high
    var offsetIndex = needle.startIndex    // Tracks position `high - low` in `needle`
    
    // Stage 2: Continue building the z-array until finding a position that matches a
    // prefix the length of `needle`.

    var i = high + 1
    while i < needleCount + 1 + c.count {
      defer { i += 1 }
      
      if i <= high {
        let k = z[i - low]
        if k < high - i + 1 {
          z.append(k)
          if k == needleCount && i >= startOffset {
            return c.index(highIndex, offsetBy: -needleCount) ..< highIndex
          }
          continue
        }
      }

      c.formIndex(&highIndex, offsetBy: i - high)
      offsetIndex = needle.startIndex
      high = i
      low = i

      while highIndex < c.endIndex && offsetIndex < needle.endIndex && needle[offsetIndex] == c[highIndex] {
        high += 1
        c.formIndex(after: &highIndex)
        needle.formIndex(after: &offsetIndex)
      }

      z.append(high - low)
      if high - low == needleCount && i >= startOffset {
        return c.index(highIndex, offsetBy: -needleCount) ..< highIndex
      }

      high -= 1
      c.formIndex(before: &highIndex)
    }
    
    return nil
  }
}
