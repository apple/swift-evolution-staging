
public enum SearchStatistics {
    public static var EqualityComparisons = 0
    public static var LessThanComparisons = 0
    public static var IndexMoves: [Int: Int] = [:]
    public static var Distances: [Int: Int] = [:]

    public static func reset() {
        EqualityComparisons = 0
        LessThanComparisons = 0
        IndexMoves = [:]
        Distances = [:]
    }

    public static func report() -> String {
        """
        --------------------------------------
        Collection statistics
        - Index moves:              \(IndexMoves)
        - Distance calculations:    \(Distances)
        Comparison statistics
        - Equality checks:          \(EqualityComparisons)
        - Ordering checks:          \(LessThanComparisons)
        """
    }
    
    public static var comparisons: Int {
        EqualityComparisons + LessThanComparisons
    }
}

extension String {
    public func bracketing(_ ranges: [Range<String.Index>]) -> String {
        var insertions: [(String.Index, Character)] =
            ranges.map { ($0.lowerBound, "(") } + ranges.map { ($0.upperBound, ")") }
        insertions.sort(by: { $0.0 < $1.0 })
        
        var current = startIndex
        var result = ""
        for (end, insertion) in insertions {
            result.append(contentsOf: self[current..<end])
            result.append(insertion)
            current = end
        }
        result.append(contentsOf: self[current...])
        return result
    }
}

public struct StatsCollecting<T: Comparable>: Comparable {
    public var value: T

    public init(_ value: T) {
        self.value = value
    }

    public static func ==(lhs: Self, rhs: Self) -> Bool {
        SearchStatistics.EqualityComparisons += 1
        return lhs.value == rhs.value
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        SearchStatistics.LessThanComparisons += 1
        return lhs.value < rhs.value
    }
}

public struct StatsCollectingCollection<Base: Collection>: Collection
    where Base.Element: Comparable
{
    var base: Base
    var id: Int

    public init(_ base: Base) {
        self.base = base
        self.id = (SearchStatistics.IndexMoves.keys.max() ?? 0) + 1
    }

    public var startIndex: Base.Index {
        base.startIndex
    }

    public var endIndex: Base.Index {
        base.endIndex
    }

    public subscript(i: Base.Index) -> StatsCollecting<Base.Element> {
        StatsCollecting(base[i])
    }

    public func index(after i: Base.Index) -> Base.Index {
        SearchStatistics.IndexMoves[id, default: 0] += 1
        return base.index(after: i)
    }

    public func index(_ i: Base.Index, offsetBy n: Int) -> Base.Index {
        SearchStatistics.IndexMoves[id, default: 0] += abs(n)
        return base.index(i, offsetBy: n)
    }

    public func index(_ i: Base.Index, offsetBy n: Int, limitedBy limit: Base.Index) -> Base.Index? {
        SearchStatistics.IndexMoves[id, default: 0] += abs(n)
        return base.index(i, offsetBy: n, limitedBy: limit)
    }

    public func distance(from start: Base.Index, to end: Base.Index) -> Int {
        let n = base.distance(from: start, to: end)
        SearchStatistics.Distances[id, default: 0] += abs(n)
        return n
    }
}

extension StatsCollectingCollection: BidirectionalCollection
    where Base: BidirectionalCollection 
{
    public func index(before i: Base.Index) -> Base.Index {
        SearchStatistics.IndexMoves[id, default: 0] += 1
        return base.index(before: i)
    }
}
