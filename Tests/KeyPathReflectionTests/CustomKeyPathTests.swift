import XCTest
@testable import KeyPathReflection
import Foundation

private protocol MyProtocol {}
extension Int: MyProtocol {}

private final class MyFinalClass {
  let float: Float = 0
  var int: Int = 0
  // FIXME: Weak and unowned fields are not supported.
  // weak var cls: Class? = nil
}

private struct MyStruct<T: Equatable> {
  var existential: MyProtocol
  var generic: [T]
}

extension MyStruct: MyProtocol {}
extension MyFinalClass: MyProtocol {}

/// Asserts that the given named key path collections are equal.
func assertNamedKeyPathsEqual<KeyPath: AnyKeyPath>(
  _ actual: [(name: String, keyPath: KeyPath)],
  _ expected: [(name: String, keyPath: KeyPath)],
  file: StaticString = #file,
  line: UInt = #line
) {
  for (actual, expected) in zip(actual, expected) {
    XCTAssertEqual(actual.name, expected.name, file: file, line: line)
    XCTAssertEqual(actual.keyPath, expected.keyPath, file: file, line: line)
  }
}

final class CustomKeyPathTests: XCTestCase {
    func testStruct() throws {
        let s = MyStruct<Int>(existential: 1, generic: [2, 3])
        let allKeyPaths = Reflection.allKeyPaths(for: s)
        XCTAssertEqual(
          allKeyPaths,
          [\MyStruct<Int>.existential, \MyStruct<Int>.generic])

        let allNamedKeyPaths = Reflection.allNamedKeyPaths(for: s)
        assertNamedKeyPathsEqual(
          allNamedKeyPaths,
          [
            ("existential", \MyStruct<Int>.existential),
            ("generic", \MyStruct<Int>.generic),
          ])
    }

    func testClass() throws {
        let c = MyFinalClass()
        let allKeyPaths = Reflection.allKeyPaths(for: c)
        XCTAssertEqual(allKeyPaths, [\MyFinalClass.float, \MyFinalClass.int])

        let allNamedKeyPaths = Reflection.allNamedKeyPaths(for: c)
        assertNamedKeyPathsEqual(
          allNamedKeyPaths,
          [("float", \MyFinalClass.float), ("int", \MyFinalClass.int)])

        // FIXME: Handle and test non-final class properties and weak/unowned
        // properties.
    }

    func testExistential() throws {
      let s = MyStruct<Int>(existential: 1, generic: [2, 3])
      let c = MyFinalClass()
      func test<T>(erasingAs existentialType: T.Type) {
        // Struct
        let existentialStruct = s as! T
        XCTAssertEqual(
          Reflection.allKeyPaths(for: existentialStruct),
          [\MyStruct<Int>.existential, \MyStruct<Int>.generic])
        assertNamedKeyPathsEqual(
          Reflection.allNamedKeyPaths(for: existentialStruct),
          [
            ("existential", \MyStruct<Int>.existential),
            ("generic", \MyStruct<Int>.generic)
          ])
        // Class
        let existentialClass = c as! T
        XCTAssertEqual(
          Reflection.allKeyPaths(for: existentialClass),
          [\MyFinalClass.float, \MyFinalClass.int])
        assertNamedKeyPathsEqual(
          Reflection.allNamedKeyPaths(for: existentialClass),
          [("float", \MyFinalClass.float), ("int", \MyFinalClass.int)])
      }
      test(erasingAs: Any.self)
      test(erasingAs: MyProtocol.self)
    }

    func testOptional() throws {
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

    func testArray() throws {
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
