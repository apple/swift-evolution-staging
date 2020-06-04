//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import XCTest
import SE0000_AdjacentPairs

final class SENNNN_AdjacentPairsTests: XCTestCase {
    func testZeroElements() {
        let pairs = (0..<0).adjacentPairs()
        XCTAssertEqual(pairs.startIndex, pairs.endIndex)
        XCTAssert(Array(pairs) == [])
    }

    func testOneElement() {
        let pairs = (0..<1).adjacentPairs()
        XCTAssertEqual(pairs.startIndex, pairs.endIndex)
        XCTAssert(Array(pairs) == [])
    }

    func testTwoElements() {
        let pairs = (0..<2).adjacentPairs()
        XCTAssert(Array(pairs) == [(0, 1)])
    }

    func testThreeElements() {
        let pairs = (0..<3).adjacentPairs()
        XCTAssert(Array(pairs) == [(0, 1), (1, 2)])
    }

    func testFourElements() {
        let pairs = (0..<4).adjacentPairs()
        XCTAssert(Array(pairs) == [(0, 1), (1, 2), (2, 3)])
    }

    func testForwardIndexing() {
        let pairs = (1...5).adjacentPairs()
        let expected = [(1, 2), (2, 3), (3, 4), (4, 5)]
        var index = pairs.startIndex
        for iteration in expected.indices {
            XCTAssert(pairs[index] == expected[iteration])
            pairs.formIndex(after: &index)
        }
        XCTAssertEqual(index, pairs.endIndex)
    }

    func testBackwardIndexing() {
        let pairs = (1...5).adjacentPairs()
        let expected = [(4, 5), (3, 4), (2, 3), (1, 2)]
        var index = pairs.endIndex
        for iteration in expected.indices {
            pairs.formIndex(before: &index)
            XCTAssert(pairs[index] == expected[iteration])
        }
        XCTAssertEqual(index, pairs.startIndex)
    }

    func testIndexDistance() {
        let pairSequences = (0...4).map { (0..<$0).adjacentPairs() }

        for pairs in pairSequences {
            for index in pairs.indices.dropLast() {
                let next = pairs.index(after: index)
                XCTAssertEqual(pairs.distance(from: index, to: next), 1)
            }

            XCTAssertEqual(pairs.distance(from: pairs.startIndex, to: pairs.endIndex), pairs.count)
            XCTAssertEqual(pairs.distance(from: pairs.endIndex, to: pairs.startIndex), -pairs.count)
        }
    }
}

