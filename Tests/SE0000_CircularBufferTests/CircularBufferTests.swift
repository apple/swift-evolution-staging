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
import SE0000_CircularBuffer

private func makeCircularBuffer<S: Sequence>(frontSequence: S, backSequence: S, capacity: Int) -> CircularBuffer<S.Element> {
  var circularBuffer = CircularBuffer<S.Element>(capacity: capacity)
  circularBuffer.pushFront(contentsOf: frontSequence)
  circularBuffer.pushBack(contentsOf: backSequence)

  return circularBuffer
}

final class SENNNN_CircularBufferTests: XCTestCase {

  // MARK: CircularBuffer init tests

  func testCapacityInit() {
    let circularBuffer = CircularBuffer<Int>(capacity: 3)
    XCTAssertEqual(circularBuffer, [])
    XCTAssertEqual(circularBuffer.capacity, 3)
    XCTAssertEqual(circularBuffer.count, 0)
    XCTAssertEqual(circularBuffer.underestimatedCount, 0)
    XCTAssertEqual(circularBuffer.isEmpty, true)
    XCTAssertEqual(circularBuffer.isFull, false)
  }

  func testArrayLiteralInit() {
    let circularBuffer: CircularBuffer<Int> = [1, 2, 3]
    XCTAssertEqual(circularBuffer.capacity, 3)
    XCTAssertEqual(circularBuffer, [1, 2, 3])
    XCTAssertEqual(circularBuffer.count, 3)
    XCTAssertEqual(circularBuffer.underestimatedCount, 3)
    XCTAssertEqual(circularBuffer.isEmpty, false)
    XCTAssertEqual(circularBuffer.isFull, true)
  }

  func testSequenceInit() {
    let array: ContiguousArray<Int> = [1, 2, 3]
    let circularBuffer: CircularBuffer<Int> = CircularBuffer<Int>(array)
    XCTAssertEqual(circularBuffer.capacity, 3)
    XCTAssertEqual(circularBuffer, [1, 2, 3])
    XCTAssertEqual(circularBuffer.count, 3)
    XCTAssertEqual(circularBuffer.underestimatedCount, 3)
    XCTAssertEqual(circularBuffer.isEmpty, false)
    XCTAssertEqual(circularBuffer.isFull, true)
  }

  func testRepatedInit() {
    let circularBuffer: CircularBuffer<Int> = CircularBuffer<Int>.init(repeating: 1, count: 3)
    XCTAssertEqual(circularBuffer.capacity, 3)
    XCTAssertEqual(circularBuffer, [1, 1, 1])
    XCTAssertEqual(circularBuffer.count, 3)
    XCTAssertEqual(circularBuffer.underestimatedCount, 3)
    XCTAssertEqual(circularBuffer.isEmpty, false)
    XCTAssertEqual(circularBuffer.isFull, true)
  }

  func testEmptyInit() {
    let circularBuffer = CircularBuffer<Int>()
    XCTAssertEqual(circularBuffer.capacity, 0)
    XCTAssertEqual(circularBuffer, [])
    XCTAssertEqual(circularBuffer.count, 0)
    XCTAssertEqual(circularBuffer.underestimatedCount, 0)
    XCTAssertEqual(circularBuffer.isEmpty, true)
    XCTAssertEqual(circularBuffer.isFull, true)
  }

  // MARK: CircularBuffer push pop method tests

  func testPushBack() {
    var circularBuffer = CircularBuffer<Int>(capacity: 3)
    circularBuffer.pushBack(1)
    circularBuffer.pushBack(2)
    circularBuffer.pushBack(3)
    XCTAssertEqual(circularBuffer, [1, 2, 3])
    circularBuffer.pushBack(4)
    XCTAssertEqual(circularBuffer, [2, 3, 4])
    circularBuffer.pushBack(5)
    XCTAssertEqual(circularBuffer, [3, 4, 5])
    circularBuffer.pushBack(6)
    XCTAssertEqual(circularBuffer, [4, 5, 6])
    circularBuffer.pushBack(contentsOf: [7, 8, 9])
    XCTAssertEqual(circularBuffer, [7, 8, 9])
  }

  func testPushBackCOW() {
    var circularBuffer = CircularBuffer<Int>(capacity: 3)
    circularBuffer.pushBack(1)
    var copy = circularBuffer
    copy.pushBack(2)
    XCTAssertEqual(circularBuffer, [1])
    XCTAssertEqual(copy, [1, 2])
  }

  func testPushBackSequenceCOW() {
    var circularBuffer = CircularBuffer<Int>(capacity: 3)
    circularBuffer.pushBack(1)
    var copy = circularBuffer
    copy.pushBack(contentsOf: [2, 3])

    XCTAssertEqual(circularBuffer, [1])
    XCTAssertEqual(copy, [1, 2, 3])
  }

  func testPopBack() {
    var circularBuffer = CircularBuffer<Int>(capacity: 3)
    circularBuffer.pushBack(1)
    XCTAssertEqual(circularBuffer.popBack(), 1)
    circularBuffer.pushBack(2)
    circularBuffer.pushBack(3)
    circularBuffer.pushBack(4)
    circularBuffer.pushBack(5)
    XCTAssertEqual(circularBuffer, [3, 4, 5])
    XCTAssertEqual(circularBuffer.popBack(), 5)
    XCTAssertEqual(circularBuffer, [3, 4])
    XCTAssertEqual(circularBuffer.popBack(), 4)
    XCTAssertEqual(circularBuffer.popBack(), 3)
    XCTAssertEqual(circularBuffer, [])
  }

  func testPopBackCOW() {
    var circularBuffer = CircularBuffer<Int>(capacity: 3)
    circularBuffer.pushBack(1)
    var copy = circularBuffer
    copy.popBack()

    XCTAssertEqual(circularBuffer, [1])
    XCTAssertEqual(copy, [])
  }

  func testPushFront() {
    var circularBuffer = CircularBuffer<Int>(capacity: 3)
    circularBuffer.pushFront(1)
    circularBuffer.pushFront(2)
    circularBuffer.pushFront(3)
    XCTAssertEqual(circularBuffer, [3, 2, 1])
    circularBuffer.pushFront(4)
    XCTAssertEqual(circularBuffer, [4, 3, 2])
    circularBuffer.pushFront(5)
    XCTAssertEqual(circularBuffer, [5, 4, 3])
    circularBuffer.pushFront(6)
    XCTAssertEqual(circularBuffer, [6, 5, 4])
    circularBuffer.pushFront(contentsOf: [7, 8, 9])
    XCTAssertEqual(circularBuffer, [9, 8, 7])
  }

  func testPushFrontCOW() {
    var circularBuffer = CircularBuffer<Int>(capacity: 3)
    circularBuffer.pushFront(1)

    var copy = circularBuffer
    copy.pushFront(2)

    XCTAssertEqual(circularBuffer, [1])
    XCTAssertEqual(copy, [2, 1])
  }

  func testPushFrontSequenceCOW() {
    var circularBuffer = CircularBuffer<Int>(capacity: 3)
    circularBuffer.pushFront(1)

    var copy = circularBuffer
    copy.pushFront(contentsOf: [2, 3])

    XCTAssertEqual(circularBuffer, [1])
    XCTAssertEqual(copy, [3, 2, 1])
  }

  func testPopFront() {
    var circularBuffer = CircularBuffer<Int>(capacity: 3)
    circularBuffer.pushFront(1)
    circularBuffer.pushFront(2)
    circularBuffer.pushFront(3)
    XCTAssertEqual(circularBuffer, [3, 2, 1])
    XCTAssertEqual(circularBuffer.popFront(), 3)
    XCTAssertEqual(circularBuffer, [2, 1])
    circularBuffer.pushFront(5)
    circularBuffer.pushFront(6)
    XCTAssertEqual(circularBuffer, [6, 5, 2])
    XCTAssertEqual(circularBuffer.popFront(), 6)
    XCTAssertEqual(circularBuffer.popFront(), 5)
    XCTAssertEqual(circularBuffer, [2])
    XCTAssertEqual(circularBuffer.popFront(), 2)
    XCTAssertEqual(circularBuffer, [])
  }

  func testPopFrontCOW() {
    var circularBuffer = CircularBuffer<Int>(capacity: 3)
    circularBuffer.pushFront(1)

    var copy = circularBuffer

    copy.popFront()

    XCTAssertEqual(circularBuffer, [1])
    XCTAssertEqual(copy, [])
  }

  func testMakeCircularBuffer() {
    var circularBuffer = CircularBuffer<Int>(capacity: 3)
    circularBuffer.pushFront(1)
    circularBuffer.pushFront(2)
    circularBuffer.pushBack(1)
    circularBuffer.pushBack(2)
    circularBuffer.pushBack(3)
    XCTAssertEqual(circularBuffer, makeCircularBuffer(frontSequence: [1, 2], backSequence: [1, 2, 3], capacity: 3))
  }

  // MARK: CircularBuffer capacity tests

  func testResizeCapacityToZero() {
    var circularBuffer = makeCircularBuffer(frontSequence: [1], backSequence: [2, 3], capacity: 3)
    XCTAssertEqual(circularBuffer.isFull, true)
    circularBuffer.resize(newCapacity: 0)
    XCTAssertEqual(circularBuffer.isFull, true)
    XCTAssertEqual(circularBuffer.isEmpty, true)
    XCTAssertEqual(circularBuffer.map { $0 }, [])
    circularBuffer.pushFront(1)
    circularBuffer.pushBack(2)
    XCTAssertEqual(circularBuffer.isFull, true)
    XCTAssertEqual(circularBuffer.isEmpty, true)
    XCTAssertEqual(circularBuffer.map { $0 }, [])
  }

  func testResizeCapacityEqual() {
    var circularBuffer = makeCircularBuffer(frontSequence: [1], backSequence: [2, 3], capacity: 3)
    circularBuffer.resize(newCapacity: 3)
    XCTAssertEqual(circularBuffer.isFull, true)
    circularBuffer.pushBack(4)
    XCTAssertEqual(circularBuffer, [2, 3, 4])
  }

  func testResizeCapacityHigher() {
    var circularBuffer = makeCircularBuffer(frontSequence: [1], backSequence: [2, 3], capacity: 3)
    XCTAssertEqual(circularBuffer.isFull, true)
    circularBuffer.pushBack(4)
    XCTAssertEqual(circularBuffer, [2, 3, 4])
    circularBuffer.resize(newCapacity: 5)
    XCTAssertEqual(circularBuffer.capacity, 5)
    circularBuffer.pushFront(5)
    circularBuffer.pushBack(6)
    XCTAssertEqual(circularBuffer, [5, 2, 3, 4, 6])
    XCTAssertEqual(circularBuffer.isFull, true)
    circularBuffer.pushBack(7)
    circularBuffer.pushBack(8)
    XCTAssertEqual(circularBuffer, [3, 4, 6, 7, 8])
  }

  func testResizeCapacityLower() {
    /// Case 1: Elements are between head and tail without wrapping at the end of array
    var firstCase = makeCircularBuffer(frontSequence: [], backSequence: [1, 2, 3], capacity: 3)
    XCTAssertEqual(firstCase.isFull, true)
    firstCase.resize(newCapacity: 2)
    XCTAssertEqual(firstCase.capacity, 2)
    XCTAssertEqual(firstCase.isFull, true)
    XCTAssertEqual(firstCase, [1, 2])
    /// Case 2: Elements after head greater or equal to elements to move
    var secondCase = makeCircularBuffer(frontSequence: [1], backSequence: [2, 3], capacity: 3)
    XCTAssertEqual(secondCase.isFull, true)
    secondCase.resize(newCapacity: 1)
    XCTAssertEqual(secondCase.capacity, 1)
    XCTAssertEqual(secondCase.isFull, true)
    XCTAssertEqual(secondCase, [1])
    /// Case 3: Elements after head lower than elements to move
    var thirdCase = makeCircularBuffer(frontSequence: [1], backSequence: [2, 3], capacity: 3)
    XCTAssertEqual(thirdCase.isFull, true)
    thirdCase.resize(newCapacity: 2)
    XCTAssertEqual(thirdCase.capacity, 2)
    XCTAssertEqual(thirdCase.isFull, true)
    XCTAssertEqual(thirdCase, [1, 2])
  }

  func testResizeCOW() {
    var circularBuffer = CircularBuffer<Int>(capacity: 3)
    circularBuffer.pushBack(1)

    var copy = circularBuffer

    copy.resize(newCapacity: 4)

    XCTAssertEqual(circularBuffer.capacity, 3)
    XCTAssertEqual(copy.capacity, 4)
    XCTAssertEqual(circularBuffer, [1])
    XCTAssertEqual(copy, [1])
  }

  // MARK: CircularBuffer RandomAccessCollection method tests

  func testRandomAccessCollectionMethods() {
    var circularBuffer = makeCircularBuffer(frontSequence: [1], backSequence: [2, 3], capacity: 3)
    XCTAssertEqual(circularBuffer.startIndex, 0)
    XCTAssertEqual(circularBuffer.endIndex, 3)
    XCTAssertEqual(circularBuffer[0], 1)
    XCTAssertEqual(circularBuffer[1], 2)
    XCTAssertEqual(circularBuffer[2], 3)
    XCTAssertEqual(circularBuffer[0...2].map { $0 }, [1, 2, 3])
    circularBuffer.pushFront(4)
    XCTAssertEqual(circularBuffer[0...2].map { $0 }, [4, 1, 2])
    circularBuffer.pushFront(5)
    XCTAssertEqual(circularBuffer[0...2].map { $0  }, [5, 4, 1])
    XCTAssertEqual(circularBuffer.index(after: 0), 1)
    XCTAssertEqual(circularBuffer.index(before: 1), 0)
    XCTAssertEqual(circularBuffer.index(0, offsetBy: 1), 1)
    var index = 0
    circularBuffer.formIndex(after: &index)
    XCTAssertEqual(index, 1)
    circularBuffer.formIndex(before: &index)
    XCTAssertEqual(index, 0)
    circularBuffer.formIndex(&index, offsetBy: 1)
    XCTAssertEqual(index, 1)
  }

  func testRandomAccessCollectionMethodsCOW() {
    let circularBuffer = makeCircularBuffer(frontSequence: [1], backSequence: [2, 3], capacity: 3)
    XCTAssertEqual(circularBuffer[0], 1)

    var copy = circularBuffer
    copy[0] = 4

    XCTAssertEqual(circularBuffer[0], 1)
    XCTAssertEqual(copy[0], 4)
  }

  // MARK: CircularBuffer RangeReplaceableCollection method tests

  func testReplaceSubrange() {
    /// Case 1: Elements count equal zero
    var firstCase: CircularBuffer<Int> = makeCircularBuffer(frontSequence: [2, 1], backSequence: [3, 4, 5], capacity: 5)
    firstCase.replaceSubrange(0..<3, with: [])
    XCTAssertEqual(firstCase, [4, 5])
    firstCase.pushBack(6)
    XCTAssertEqual(firstCase, [4, 5, 6])
    firstCase.pushFront(7)
    XCTAssertEqual(firstCase, [7, 4, 5, 6])
    /// Case 2: Subrange count equal elements count
    var secondCase = makeCircularBuffer(frontSequence: [1, 2], backSequence: [3, 4, 5], capacity: 5)
    secondCase.replaceSubrange(0..<3, with: [3, 2, 1])
    XCTAssertEqual(secondCase, [3, 2, 1, 4, 5])
    secondCase.pushBack(6)
    XCTAssertEqual(secondCase, [2, 1, 4, 5, 6])
    secondCase.pushFront(7)
    XCTAssertEqual(secondCase, [7, 2, 1, 4, 5])
    /// Case 3: Subrange count greater than elements count
    var thirdCase: CircularBuffer<Int> = makeCircularBuffer(frontSequence: [2, 1], backSequence: [3, 4, 5], capacity: 5)
    thirdCase.replaceSubrange(0..<4, with: [6, 7, 8])
    XCTAssertEqual(thirdCase, [6, 7, 8, 5])
    thirdCase.pushBack(9)
    XCTAssertEqual(thirdCase, [6, 7, 8, 5, 9])
    thirdCase.pushFront(10)
    XCTAssertEqual(thirdCase, [10, 6, 7, 8, 5])
    /// Case 4: Subrange count less than elements count with additional capacity
    var fourthCase = makeCircularBuffer(frontSequence: [2, 1], backSequence: [3], capacity: 3)
    fourthCase.replaceSubrange(0..<1, with: [3, 4, 5])
    XCTAssertEqual(fourthCase, [3, 4, 5, 2, 3])
    fourthCase.pushBack(6)
    XCTAssertEqual(fourthCase, [4, 5, 2, 3, 6])
    fourthCase.pushFront(7)
    XCTAssertEqual(fourthCase, [7, 4, 5, 2, 3])
    /// Case 5: Subrange count less than elements count without additional capacity
    var fifthCase = makeCircularBuffer(frontSequence: [2, 1], backSequence: [3], capacity: 5)
    fifthCase.replaceSubrange(0..<3, with: [1, 2, 3, 4, 5])
    XCTAssertEqual(fifthCase, [1, 2, 3, 4, 5])
    fifthCase.pushBack(6)
    XCTAssertEqual(fifthCase, [2, 3, 4, 5, 6])
    fifthCase.pushFront(7)
    XCTAssertEqual(fifthCase, [7, 2, 3, 4, 5])
  }

  func testReplaceSubrangeCOW() {
    let circularBuffer = makeCircularBuffer(frontSequence: [1], backSequence: [2, 3], capacity: 3)

    var copy = circularBuffer
    copy.removeSubrange(1..<2)

    XCTAssertEqual(circularBuffer, [1, 2, 3])
    XCTAssertEqual(copy, [1, 3])
  }

  func testRemoveSubrange() {
    /// Case 1: Subrange starts with 0
    var firstCase = makeCircularBuffer(frontSequence: [1, 2], backSequence: [3, 4, 5], capacity: 5)
    firstCase.removeSubrange(0..<2)
    XCTAssertEqual(firstCase, [3, 4, 5])
    /// Case 2: Subrange ends with circular array end
    var secondCase = makeCircularBuffer(frontSequence: [2, 1], backSequence: [3, 4, 5], capacity: 5)
    XCTAssertEqual(secondCase, [1, 2, 3, 4, 5])
    secondCase.removeSubrange(3..<5)
    XCTAssertEqual(secondCase, [1, 2, 3])
    /// Case 3: Subrange start and ends between head and tail without wrapping at the end of array
    var thirdCase = makeCircularBuffer(frontSequence: [], backSequence: [1, 2, 3, 4, 5], capacity: 5)
    thirdCase.removeSubrange(2..<3)
    XCTAssertEqual(thirdCase, [1, 2, 4, 5])
    ///  Case 4: Subrange start and ends between head and tail with wrapping at the end of array and head + lower bound greater than capacity
    var fourthCase = makeCircularBuffer(frontSequence: [2, 1], backSequence: [3, 4, 5], capacity: 5)
    fourthCase.removeSubrange(3..<4)
    XCTAssertEqual(fourthCase, [1, 2, 3, 5])
    ///  Case 5: Subrange start and ends between head and tail with wrapping at the end of array and head + upper bound greater than capacity
    var fifthCase = makeCircularBuffer(frontSequence: [2, 1], backSequence: [3, 4, 5], capacity: 5)
    fifthCase.removeSubrange(1..<3)
    XCTAssertEqual(fifthCase, [1, 4, 5])
  }

  func testRemoveSubrangeEmpty() {
    var circularBuffer = makeCircularBuffer(frontSequence: [2, 1], backSequence: [3, 4, 5], capacity: 5)
    circularBuffer.removeSubrange(4..<4)
    XCTAssertEqual(circularBuffer, [1, 2, 3, 4, 5])
  }

  func testRemoveSubrangeFull() {
    var circularBuffer = makeCircularBuffer(frontSequence: [2, 1], backSequence: [3, 4, 5], capacity: 5)
    circularBuffer.removeSubrange(0..<5)
    XCTAssertEqual(circularBuffer, [])
  }

  func testRemoveSubrangeCOW() {
    let circularBuffer = makeCircularBuffer(frontSequence: [1], backSequence: [2, 3], capacity: 3)
    XCTAssertEqual(circularBuffer[0], 1)

    var copy = circularBuffer
    copy.removeSubrange(1..<2)

    XCTAssertEqual(circularBuffer, [1, 2, 3])
    XCTAssertEqual(copy, [1, 3])
  }

  func testInsertSingleElementAtIndex() {
    var circularBuffer = makeCircularBuffer(frontSequence: [2, 1], backSequence: [3, 4, 5], capacity: 5)
    circularBuffer.insert(6, at: 0)
    XCTAssertEqual(circularBuffer.capacity, 6)
    XCTAssertEqual(circularBuffer, [6, 1, 2, 3, 4, 5])
    circularBuffer.insert(7, at: 6)
    XCTAssertEqual(circularBuffer.capacity, 7)
    XCTAssertEqual(circularBuffer, [6, 1, 2, 3, 4, 5, 7])
    circularBuffer.insert(8, at: 3)
    XCTAssertEqual(circularBuffer.capacity, 8)
    XCTAssertEqual(circularBuffer, [6, 1, 2, 8, 3, 4, 5, 7])
  }

  func testInsertSingleElementAtIndexCOW() {
    let circularBuffer = makeCircularBuffer(frontSequence: [1], backSequence: [2, 3], capacity: 3)

    var copy = circularBuffer
    copy.insert(4, at: 0)

    XCTAssertEqual(circularBuffer, [1, 2, 3])
    XCTAssertEqual(copy, [4, 1, 2, 3])
  }

  func testInsertMultipleElementsAtIndex() {
    var circularBuffer = makeCircularBuffer(frontSequence: [2, 1], backSequence: [3, 4, 5], capacity: 5)
    circularBuffer.insert(contentsOf: [6, 7], at: 0)
    XCTAssertEqual(circularBuffer.capacity, 7)
    XCTAssertEqual(circularBuffer, [6, 7, 1, 2, 3, 4, 5])
    circularBuffer.insert(contentsOf: [7, 8], at: 7)
    XCTAssertEqual(circularBuffer.capacity, 9)
    XCTAssertEqual(circularBuffer, [6, 7, 1, 2, 3, 4, 5, 7, 8])
    circularBuffer.insert(contentsOf: [8, 9], at: 3)
    XCTAssertEqual(circularBuffer.capacity, 11)
    XCTAssertEqual(circularBuffer, [6, 7, 1, 8, 9, 2, 3, 4, 5, 7, 8])
  }

  func testInsertMultipleElementsAtIndexCOW() {
    let circularBuffer = makeCircularBuffer(frontSequence: [1], backSequence: [2, 3], capacity: 3)

    var copy = circularBuffer
    copy.insert(contentsOf: [4, 5], at: 0)

    XCTAssertEqual(circularBuffer, [1, 2, 3])
    XCTAssertEqual(copy, [4, 5, 1, 2, 3])
  }

  func testRemoveAtIndex() {
    var circularBuffer = makeCircularBuffer(frontSequence: [2, 1], backSequence: [3, 4, 5], capacity: 5)
    circularBuffer.remove(at: 0)
    XCTAssertEqual(circularBuffer, [2, 3, 4, 5])
    circularBuffer.remove(at: 3)
    XCTAssertEqual(circularBuffer, [2, 3, 4])
    circularBuffer.remove(at: 1)
    XCTAssertEqual(circularBuffer, [2, 4])
  }

  func testRemoveAtIndexCOW() {
    let circularBuffer = makeCircularBuffer(frontSequence: [1], backSequence: [2, 3], capacity: 3)

    var copy = circularBuffer
    copy.remove(at: 1)

    XCTAssertEqual(circularBuffer, [1, 2, 3])
    XCTAssertEqual(copy, [1, 3])
  }


  func testReserveCapacity() {
    var circularBuffer = makeCircularBuffer(frontSequence: [1], backSequence: [2, 3], capacity: 3)
    circularBuffer.pushFront(4)
    XCTAssertEqual(circularBuffer, [4, 1, 2])
    circularBuffer.reserveCapacity(2)
    circularBuffer.pushBack(5)
    circularBuffer.pushFront(6)
    XCTAssertEqual(circularBuffer, [6, 4, 1, 2, 5])
    circularBuffer.pushBack(7)
    XCTAssertEqual(circularBuffer, [4, 1, 2, 5, 7])
    circularBuffer.pushFront(8)
    XCTAssertEqual(circularBuffer, [8, 4, 1, 2, 5])
  }

  func testReserveCapacityCOW() {
    let circularBuffer = makeCircularBuffer(frontSequence: [1], backSequence: [2, 3], capacity: 3)
    XCTAssertEqual(circularBuffer.capacity, 3)

    var copy = circularBuffer
    XCTAssertEqual(copy.capacity, 3)

    copy.reserveCapacity(1)
    XCTAssertEqual(circularBuffer.capacity, 3)
    XCTAssertEqual(copy.capacity, 4)
  }

  func testAppend() {
    var circularBuffer = makeCircularBuffer(frontSequence: [1], backSequence: [], capacity: 1)
    circularBuffer.popFront()
    XCTAssertEqual(circularBuffer.isEmpty, true)
    circularBuffer.append(1)
    circularBuffer.append(2)
    XCTAssertEqual(circularBuffer.isEmpty, false)
    XCTAssertEqual(circularBuffer.capacity, 2)
    XCTAssertEqual(circularBuffer, [1, 2])
    circularBuffer.pushBack(3)
    XCTAssertEqual(circularBuffer, [2, 3])
    circularBuffer.pushFront(4)
    XCTAssertEqual(circularBuffer, [4, 2])
    circularBuffer.append(contentsOf: [1, 2, 3, 4])
    XCTAssertEqual(circularBuffer.capacity, 6)
    XCTAssertEqual(circularBuffer, [4, 2, 1, 2, 3, 4])
    circularBuffer.pushFront(5)
    XCTAssertEqual(circularBuffer, [5, 4, 2, 1, 2, 3])
    circularBuffer.pushBack(6)
    XCTAssertEqual(circularBuffer, [4, 2, 1, 2, 3, 6])
  }

  func testAppendCOW() {
    let circularBuffer = makeCircularBuffer(frontSequence: [1], backSequence: [2, 3], capacity: 3)
    XCTAssertEqual(circularBuffer.capacity, 3)

    var copy = circularBuffer
    XCTAssertEqual(copy.capacity, 3)

    copy.append(1)
    XCTAssertEqual(circularBuffer.capacity, 3)
    XCTAssertEqual(copy.capacity, 4)
  }

  func testAppendSequenceCOW() {
    let circularBuffer = makeCircularBuffer(frontSequence: [1], backSequence: [2, 3], capacity: 3)
    XCTAssertEqual(circularBuffer.capacity, 3)

    var copy = circularBuffer
    XCTAssertEqual(copy.capacity, 3)

    copy.append(contentsOf: [1, 2])
    XCTAssertEqual(circularBuffer.capacity, 3)
    XCTAssertEqual(copy.capacity, 5)
  }

  func testRemoveFromBack() {
    var circularBuffer = makeCircularBuffer(frontSequence: [1], backSequence: [2, 3], capacity: 3)
    circularBuffer.removeLast()
    XCTAssertEqual(circularBuffer, [1, 2])
    circularBuffer.removeLast(2)
    XCTAssertEqual(circularBuffer, [])
    XCTAssertEqual(circularBuffer.popLast(), nil)
    circularBuffer.pushFront(1)
    XCTAssertEqual(circularBuffer.popLast(), 1)
    circularBuffer.pushBack(2)
    circularBuffer.pushFront(1)
    XCTAssertEqual(circularBuffer, [1, 2])
  }

  func testRemoveLastCOW() {
    let circularBuffer = makeCircularBuffer(frontSequence: [1], backSequence: [2, 3], capacity: 3)

    var copy = circularBuffer

    copy.removeLast()

    XCTAssertEqual(circularBuffer, [1, 2, 3])
    XCTAssertEqual(copy, [1, 2])
  }

  func testRemoveLastKCOW() {
    let circularBuffer = makeCircularBuffer(frontSequence: [1], backSequence: [2, 3], capacity: 3)

    var copy = circularBuffer

    copy.removeLast(2)

    XCTAssertEqual(circularBuffer, [1, 2, 3])
    XCTAssertEqual(copy, [1])
  }

  func testPopLastCOW() {
    let circularBuffer = makeCircularBuffer(frontSequence: [1], backSequence: [2, 3], capacity: 3)

    var copy = circularBuffer

    copy.popLast()

    XCTAssertEqual(circularBuffer, [1, 2, 3])
    XCTAssertEqual(copy, [1, 2])
  }

  func testRemoveFromFront() {
    var circularBuffer = makeCircularBuffer(frontSequence: [1], backSequence: [2, 3], capacity: 3)

    circularBuffer.removeFirst()
    XCTAssertEqual(circularBuffer, [2, 3])
    circularBuffer.removeFirst(2)
    XCTAssertEqual(circularBuffer, [])
    XCTAssertEqual(circularBuffer.popFirst(), nil)
    circularBuffer.pushFront(1)
    XCTAssertEqual(circularBuffer.popFirst(), 1)
    circularBuffer.pushFront(2)
    circularBuffer.pushFront(3)
    XCTAssertEqual(circularBuffer, [3, 2])
  }

  func testRemoveFirstCOW() {
    let circularBuffer = makeCircularBuffer(frontSequence: [1], backSequence: [2, 3], capacity: 3)

    var copy = circularBuffer

    copy.removeFirst()

    XCTAssertEqual(circularBuffer, [1, 2, 3])
    XCTAssertEqual(copy, [2, 3])
  }

  func testPopFirstCOW() {
    let circularBuffer = makeCircularBuffer(frontSequence: [1], backSequence: [2, 3], capacity: 3)

    var copy = circularBuffer

    copy.popFirst()

    XCTAssertEqual(circularBuffer, [1, 2, 3])
    XCTAssertEqual(copy, [2, 3])
  }

  func testRemoveAllKeepingCapacityFalse() {
    var circularBuffer = makeCircularBuffer(frontSequence: [1], backSequence: [2, 3], capacity: 3)
    circularBuffer.removeAll()
    circularBuffer.pushBack(4)
    XCTAssertEqual(circularBuffer, [])
    XCTAssertEqual(circularBuffer.isEmpty, true)
    XCTAssertEqual(circularBuffer.isFull, true)
    XCTAssertEqual(circularBuffer.capacity, 0)
  }

  func testRemoveAllKeepingCapacityTrue() {
    var circularBuffer = makeCircularBuffer(frontSequence: [1], backSequence: [2, 3], capacity: 3)
    circularBuffer.removeAll(keepingCapacity: true)
    XCTAssertEqual(circularBuffer.isEmpty, true)
    XCTAssertEqual(circularBuffer.isFull, false)
    XCTAssertEqual(circularBuffer.capacity, 3)
    circularBuffer.pushBack(4)
    circularBuffer.pushBack(5)
    circularBuffer.pushFront(6)
    XCTAssertEqual(circularBuffer, [6, 4, 5])
  }

  func testRemoveAllCOW() {
    let circularBuffer = makeCircularBuffer(frontSequence: [1], backSequence: [2, 3], capacity: 3)

    var copy = circularBuffer

    copy.removeAll()

    XCTAssertEqual(circularBuffer, [1, 2, 3])
    XCTAssertEqual(copy, [])
  }

  func testRemoveAllWhere() {
    var circularBuffer = makeCircularBuffer(frontSequence: [1], backSequence: [2, 3], capacity: 3)
    circularBuffer.removeAll(where: { $0 > 1})

    XCTAssertEqual(circularBuffer.count, 1)
    XCTAssertEqual(circularBuffer, [1])
  }

  func testRemoveAllWhereCOW() {
    let circularBuffer = makeCircularBuffer(frontSequence: [1], backSequence: [2, 3], capacity: 3)

    var copy = circularBuffer

    copy.removeAll(where: { $0 > 1})

    XCTAssertEqual(circularBuffer, [1, 2, 3])
    XCTAssertEqual(copy, [1])
  }

  // MARK: CircularBuffer CustomStringConvertible method tests

  func testCustomStringConvertible() {
    XCTAssertEqual("[1, 2, 3]", CircularBuffer([1, 2, 3]).description)
    XCTAssertEqual("[\"1\", \"2\", \"3\"]", CircularBuffer(["1", "2", "3"]).description)
  }

  func testCustomDebugStringConvertible() {
    XCTAssertEqual("CircularBuffer([1, 2, 3])", CircularBuffer([1, 2, 3]).debugDescription)
    XCTAssertEqual("CircularBuffer([\"1\", \"2\", \"3\"])", CircularBuffer(["1", "2", "3"]).debugDescription)
  }

  // MARK: CircularBuffer Equatable test

  func testEquatable() {
    XCTAssertEqual(CircularBuffer<Int>([1, 2, 3]) == CircularBuffer<Int>([1, 2, 3]), true)
    XCTAssertEqual(CircularBuffer<Int>([1, 2, 3]) == CircularBuffer<Int>([1, 2]), false)
    XCTAssertEqual(CircularBuffer<Int>([1, 2, 3]) != CircularBuffer<Int>([1, 2]), true)
  }
}
