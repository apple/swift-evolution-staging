import XCTest
@testable import SE0000_KeyPathReflection

private protocol Protocol {}
extension Int: Protocol {}

private final class FinalClass {
  let float: Float = 0
  var int: Int = 0
  // FIXME: Weak and unowned fields are not supported.
  // weak var cls: Class? = nil
}

private struct Struct<T: Equatable> {
  var existential: Protocol
  var generic: [T]
}

/// Asserts that the given named key path collections are equal.
func assertNamedKeyPathsEqual<Root>(
  _ actual: [(name: String, keyPath: PartialKeyPath<Root>)],
  _ expected: [(name: String, keyPath: PartialKeyPath<Root>)],
  file: StaticString = #file,
  line: UInt = #line
) {
  for (actual, expected) in zip(actual, expected) {
    XCTAssertEqual(actual.name, expected.name, file: file, line: line)
    XCTAssertEqual(actual.keyPath, expected.keyPath, file: file, line: line)
  }
}

enum StoredPropertyKeyPaths {
  static func testStruct() throws {
    let allKeyPaths = Reflection.allKeyPaths(for: Struct<Int>.self)
    XCTAssertEqual(
      allKeyPaths,
      [\Struct<Int>.existential, \Struct<Int>.generic])

    let allNamedKeyPaths = Reflection.allNamedKeyPaths(for: Struct<Int>.self)
    assertNamedKeyPathsEqual(
      allNamedKeyPaths,
      [
        ("existential", \Struct<Int>.existential),
        ("generic", \Struct<Int>.generic),
      ])
  }

  static func testClass() throws {
    let allKeyPaths = Reflection.allKeyPaths(for: FinalClass.self)
    XCTAssertEqual(allKeyPaths, [\FinalClass.float, \FinalClass.int])

    let allNamedKeyPaths = Reflection.allNamedKeyPaths(
      for: FinalClass.self)
    assertNamedKeyPathsEqual(
      allNamedKeyPaths, [("float", \FinalClass.float), ("int", \FinalClass.int)])

    // FIXME: Handle and test non-final class properties and weak/unowned properties.
  }
}

enum CustomKeyPaths {
  static func testStruct() throws {
    let s = Struct<Int>(existential: 1, generic: [2, 3])
    let allKeyPaths = Reflection.allKeyPaths(for: s)
    XCTAssertEqual(
      allKeyPaths,
      [\Struct<Int>.existential, \Struct<Int>.generic])

    let allNamedKeyPaths = Reflection.allNamedKeyPaths(for: s)
    assertNamedKeyPathsEqual(
      allNamedKeyPaths,
      [
        ("existential", \Struct<Int>.existential),
        ("generic", \Struct<Int>.generic),
      ])
  }

  static func testClass() throws {
    let c = FinalClass()
    let allKeyPaths = Reflection.allKeyPaths(for: c)
    XCTAssertEqual(allKeyPaths, [\FinalClass.float, \FinalClass.int])

    let allNamedKeyPaths = Reflection.allNamedKeyPaths(for: c)
    assertNamedKeyPathsEqual(
      allNamedKeyPaths, [("float", \FinalClass.float), ("int", \FinalClass.int)])

    // FIXME: Handle and test non-final class properties and weak/unowned properties.
  }

  static func testOptional() throws {
    let x: Int? = nil
    XCTAssertTrue(Reflection.allKeyPaths(for: x).isEmpty)
    var y: Int? = 3
    let yKeyPaths = Reflection.allKeyPaths(for: y)
    XCTAssertEqual(yKeyPaths, [\Optional.!])
    let concreteYKeyPath = try XCTUnwrap(yKeyPaths[0] as? WritableKeyPath<Int?, Int>)
    XCTAssertEqual(y[keyPath: concreteYKeyPath], 3)
    y[keyPath: concreteYKeyPath] = 4
    XCTAssertEqual(y, 4)
  }

  static func testArray() throws {
    let array = [0, 1, 2, 3]
    let allKeyPaths = Reflection.allKeyPaths(for: array)
    XCTAssertEqual(
      allKeyPaths,
      [\[Int][0], \[Int][1], \[Int][2], \[Int][3]])
    let allNamedKeyPaths = Reflection.allNamedKeyPaths(for: array)
    assertNamedKeyPathsEqual(
      allNamedKeyPaths,
      [
        ("0", \[Int][0]),
        ("1", \[Int][1]),
        ("2", \[Int][2]),
        ("3", \[Int][3]),
      ])
  }
}

final class SE0000_KeyPathReflectionTests: XCTestCase {
  func testStoredPropertyKeyPaths() throws {
    try StoredPropertyKeyPaths.testStruct()
    try StoredPropertyKeyPaths.testClass()
  }

  func testCustomKeyPaths() throws {
    try CustomKeyPaths.testOptional()
    try CustomKeyPaths.testStruct()
    try CustomKeyPaths.testClass()
    try CustomKeyPaths.testArray()
  }
}
