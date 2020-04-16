public protocol CollectionConsumer {
  associatedtype C: Collection

  /// Returns the end of a match at the beginning of `c[s...]`, if one exists.
  ///
  /// If this consumer matches, this returns an index `e` such that
  /// `c[s..<e]` is the matched subsequence of `collection`.
  func consume(_: C, from s: C.Index) -> C.Index?
}

extension CollectionConsumer {
  /// Returns the end of a match at the beginning of `c`, if one exists.
  ///
  /// If the consumer matches, this returns an index `i` such that `c[..<i]`
  /// is the matched subsequence.
  public func consume(_ c: C) -> C.Index? {
    self.consume(c, from: c.startIndex)
  }

  /// Returns the end of a match at the beginning of `c`, or `c.startIndex`
  /// if no match is found.
  internal func _clampedConsume(_ c: C) -> C.Index {
    return consume(c) ?? c.startIndex
  }

  // FIXME(SR-11100): Remove
  internal func _clampedConsumeSR11100<Other: Collection>(_ c: Other) -> Other.Index {
    let selfResult = _clampedConsume(c as! C)
    let result = selfResult as! Other.Index
    return result
  }

}

public protocol BidirectionalCollectionConsumer: CollectionConsumer
where C: BidirectionalCollection {
  /// Returns the start of a match ending at `e`, if one exists.
  ///
  /// If the consumer matches, this returns an index `s` such that
  /// `collection[s..<e]` is the matched subsequence.
  func consumeBack(_: C, endingAt e: C.Index) -> C.Index?
}

extension BidirectionalCollectionConsumer {
  /// Returns the start of a match at the end of `c`, if one exists.
  ///
  /// If the consumer matches, this returns an index `i` such that
  /// `c[i...]` is the matched subsequence.
  public func consumeBack(_ c: C) -> C.Index? {
    return self.consumeBack(c, endingAt: c.endIndex)
  }

  /// Returns the start of a match at the end of `c`, or `c.endIndex`
  /// if no match is found.
  internal func _clampedConsumeBack(
    _ c: C
  ) -> C.Index {
    return consumeBack(c) ?? c.endIndex
  }

  internal func _clampedConsumeBoth(
    _ c: C
  ) -> Range<C.Index> {
    return _clampedConsume(c) ..< _clampedConsumeBack(c)
  }
}

internal struct _ConsumerPredicate<C: Collection>: CollectionConsumer {
  internal let predicate: (C.Element) -> Bool

  internal init(_ predicate: @escaping (C.Element) -> Bool) { self.predicate = predicate }

  internal func consume(_ c: C, from: C.Index) -> C.Index? {
    return c[from...].firstIndex { !predicate($0) } ?? c.endIndex
  }
}

extension _ConsumerPredicate: BidirectionalCollectionConsumer where C: BidirectionalCollection {
  internal func consumeBack(
    _ c: C, endingAt: C.Index
  ) -> C.Index? {
    return c[..<endingAt].reversed().firstIndex(where: { !predicate($0) })?.base ?? c.startIndex
  }
}

internal struct _ConsumerSequence<
  C: Collection, S: Sequence
>: CollectionConsumer where C.Element == S.Element, S.Element: Equatable {
  internal let seq: S

  internal init(_ s: S) { self.seq = s }

  internal typealias Element = S.Element

  internal func consume(_ c: C, from: C.Index) -> C.Index? {
    var idx = from
    for e in self.seq {
      guard e == c[idx] else { return nil }
      c.formIndex(after: &idx)
    }
    return idx
  }
}
extension _ConsumerSequence: BidirectionalCollectionConsumer
  where C: BidirectionalCollection, S: BidirectionalCollection
{
  internal func consumeBack(
    _ c: C, endingAt: C.Index
  ) -> C.Index? {
    var idx = endingAt
    for e in seq.reversed() {
      c.formIndex(before: &idx)
      guard e == c[idx] else { return nil }
    }
    return idx
  }
}
