
//
// MARK: Search Primitives
//

extension Collection {
  public func firstRange<CS: CollectionSearcher>(_ cs: CS) -> Range<Index>? where CS.C == Self {
    return cs.searchFirst(self)
  }

  public func first<CS: CollectionSearcher>(_ cs: CS) -> SubSequence? where CS.C == Self {
    guard let range = self.firstRange(cs) else { return nil }
    return self[range]
  }

  public func allRanges<CS: CollectionSearcher>(_ cs: CS, includeOverlaps: Bool = true) -> [Range<Index>]
    where CS.C == Self
  {
    var start = startIndex
    var state = cs.preprocess(self)
    var result: [Range<Index>] = []
    while let range = cs.search(self, from: start, &state) {
      result.append(range)
      start = includeOverlaps ? index(after: range.lowerBound) : range.upperBound
    }
    return result
  }
}

extension BidirectionalCollection {
  public func lastRange<CS: BidirectionalCollectionSearcher>(
    _ cs: CS
  ) -> Range<Index>? where CS.C == Self {
    return cs.searchLast(self)
  }

  public func last<CS: BidirectionalCollectionSearcher>(
    _ cs: CS
  ) -> SubSequence? where CS.C == Self {
    guard let range = self.lastRange(cs) else { return nil }
    return self[range]
  }
}

extension Collection where Element: Equatable {
  public func firstRange<S: Sequence>(_ seq: S) -> Range<Index>? where S.Element == Element {
    return self.firstRange(_SearcherSequence(seq))
  }
  
  public func allRanges<S: Sequence>(_ seq: S, includeOverlaps: Bool = true) -> [Range<Index>]
    where S.Element == Element
  {
    return self.allRanges(_SearcherSequence(seq), includeOverlaps: includeOverlaps)
  }
}

extension BidirectionalCollection where Element: Equatable {
  public func firstRange<S: BidirectionalCollection>(_ seq: S) -> Range<Index>? where S.Element == Element {
    return self.firstRange(_ZAlgorithmSearcher(seq))
  }
  
  public func allRanges<S: BidirectionalCollection>(_ seq: S, includeOverlaps: Bool = true) -> [Range<Index>]
    where S.Element == Element
  {
    return self.allRanges(_ZAlgorithmSearcher(seq), includeOverlaps: includeOverlaps)
  }

  public func lastRange<S: BidirectionalCollection>(_ seq: S) -> Range<Index>? where S.Element == Element {
    self.reversed()
      .firstRange(_ZAlgorithmSearcher(seq.reversed()))
      .map { range in range.upperBound.base ..< range.lowerBound.base }
  }
}

extension String {
  public func firstRange(_ substring: String) -> Range<Index>? {
    return self.firstRange(_TwoWayAlgorithmSearcher(substring))
  }
  
  public func allRanges(_ substring: String, includeOverlaps: Bool = true) -> [Range<Index>] {
    return self.allRanges(_TwoWayAlgorithmSearcher(substring), includeOverlaps: includeOverlaps)
  }

  public func lastRange(_ substring: String) -> Range<Index>? {
    guard let range = self.reversed().firstRange(_TwoWayAlgorithmSearcher(substring.reversed()))
      else { return nil }
    return range.upperBound.base ..< range.lowerBound.base
  }
}

//
// MARK: `tester` command helpers
//

extension BidirectionalCollection where Element: Comparable {
  public func allRangesNaive<C: BidirectionalCollection>(
    _ subsequence: C,
    includeOverlaps: Bool = true
  ) -> [Range<Index>]
    where C.Element == Element
  {
    let _self = StatsCollectingCollection(self)
    let _sub = StatsCollectingCollection(subsequence)
    return _self.allRanges(_SearcherSequence(_sub), includeOverlaps: includeOverlaps)
  }

  public func allRangesTwoWay<C: BidirectionalCollection>(
    _ subsequence: C,
    includeOverlaps: Bool = true
  ) -> [Range<Index>]
    where C.Element == Element
  {
    let _self = StatsCollectingCollection(self)
    let _sub = StatsCollectingCollection(subsequence)
    return _self.allRanges(_TwoWayAlgorithmSearcher(_sub), includeOverlaps: includeOverlaps)
  }

  public func allRangesZArray<C: BidirectionalCollection>(
    _ subsequence: C,
    includeOverlaps: Bool = true
  ) -> [Range<Index>]
    where C.Element == Element
  {
    let _self = StatsCollectingCollection(Array(self))
    let _sub = StatsCollectingCollection(Array(subsequence))
    return _self.allRanges(_ZAlgorithmSearcher(_sub), includeOverlaps: includeOverlaps)
        .map { index(startIndex, offsetBy: $0.lowerBound) ..< index(startIndex, offsetBy: $0.upperBound) }
  }
}

//
// MARK: Replace
//

extension RangeReplaceableCollection {
//  public mutating func replaceFirst<CM: CollectionSearcher & CollectionMatcher>(
//    _ cm: CM
//  ) where CM.Output: Collection, CM.Output.Element == Element, CM.C == Self {
//    guard let range = self.firstRange(cm) else { return }
//    guard let newValue = cm.validate(self, range) else { return }
//    self.replaceSubrange(range, with: newValue)
//  }
//
//  public mutating func replaceFirst<CM: CollectionSearcher & CollectionMatcher>(
//    _ cm: CM
//  ) where CM.Output == Element, CM.C == Self {
//    let matcher = _MatcherCollectionOfOne(cm)
//    self.replaceFirst(matcher)
//  }

  public mutating func replaceFirst<C: Collection, CS: CollectionSearcher>(
    _ cs: CS, with f: (SubSequence) -> C
  ) where CS.C == Self, C.Element == Element {
    guard let range = self.firstRange(cs) else { return }
    self.replaceSubrange(range, with: f(self[range]))
  }
  public mutating func replaceFirst<C: Collection, CS: CollectionSearcher>(
    _ cs: CS, with replacement: C
  ) where CS.C == Self, C.Element == Element {
    self.replaceFirst(cs) { _ in return replacement }
  }

  public mutating func replaceAll<C: Collection, CS: CollectionSearcher>(
    _ cs: CS, with f: (SubSequence) -> C
  ) where CS.C == Self, C.Element == Element {
    // TODO: In-place if possible, perhaps through a new customization hook?
    var idx = self.startIndex
    var result = Self.init()
    var state = cs.preprocess(self)

    while let range = cs.search(self, from: idx, &state) {
      result += self[idx..<range.lowerBound]
      result += f(self[range])
      idx = range.upperBound
    }
    result += self[idx...]

    self = result
  }

  public mutating func replaceAll<C: Collection, CS: CollectionSearcher>(
    _ cs: CS, with replacement: C
  ) where CS.C == Self, C.Element == Element {
    self.replaceAll(cs) { _ in return replacement }
  }
}

extension RangeReplaceableCollection where Self: BidirectionalCollection {
  public mutating func replaceLast<C: Collection, CS: BidirectionalCollectionSearcher>(
    _ cs: CS, with f: (SubSequence) -> C
    ) where CS.C == Self, C.Element == Element {
    guard let range = self.lastRange(cs) else { return }
    self.replaceSubrange(range, with: f(self[range]))
  }
  public mutating func replaceLast<C: Collection, CS: BidirectionalCollectionSearcher>(
    _ cs: CS, with replacement: C
    ) where CS.C == Self, C.Element == Element {
    self.replaceLast(cs) { _ in return replacement }
  }

}
