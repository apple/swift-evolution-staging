extension Collection {
    static func == <L: Equatable, R: Equatable> (lhs: Self, rhs: Self) -> Bool where Element == (L, R) {
        lhs.count == rhs.count && zip(lhs, rhs).allSatisfy(==)
    }
}
