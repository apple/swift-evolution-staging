import XCTest
@testable import KeyPathReflection

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


final class StoredPropertyKeyPathTests: XCTestCase {
  func testStruct() throws {
      let allKeyPaths = Reflection.allKeyPaths(for: MyStruct<Int>.self)
      XCTAssertEqual(
        allKeyPaths,
        [\MyStruct<Int>.existential, \MyStruct<Int>.generic])

      let allNamedKeyPaths = Reflection.allNamedKeyPaths(for: MyStruct<Int>.self)
      assertNamedKeyPathsEqual(
        allNamedKeyPaths,
        [
          ("existential", \MyStruct<Int>.existential),
          ("generic", \MyStruct<Int>.generic),
        ])
  }

  func testClass() throws {
    let allKeyPaths = Reflection.allKeyPaths(for: MyFinalClass.self)
    XCTAssertEqual(allKeyPaths, [\MyFinalClass.float, \MyFinalClass.int])

    let allNamedKeyPaths = Reflection.allNamedKeyPaths(
      for: MyFinalClass.self)
    assertNamedKeyPathsEqual(
      allNamedKeyPaths,
      [("float", \MyFinalClass.float), ("int", \MyFinalClass.int)])

    // FIXME: Handle and test non-final class properties and weak/unowned
    // properties.
  }

  func testExistential() throws {
    func test<T>(erasingAs existentialType: T.Type) {
      // MyStruct
      XCTAssertEqual(
        Reflection.allKeyPaths(
          forUnderlyingTypeOf: MyStruct<Int>.self as! T.Type),
        [\MyStruct<Int>.existential, \MyStruct<Int>.generic])
      assertNamedKeyPathsEqual(
        Reflection.allNamedKeyPaths(for: MyStruct<Int>.self as! T.Type),
        [
          ("existential", \MyStruct<Int>.existential),
          ("generic", \MyStruct<Int>.generic)
        ])
      // Class
      XCTAssertEqual(
        Reflection.allKeyPaths(forUnderlyingTypeOf: MyFinalClass.self as! T.Type),
        [\MyFinalClass.float, \MyFinalClass.int])
      assertNamedKeyPathsEqual(
        Reflection.allNamedKeyPaths(
            forUnderlyingTypeOf: MyFinalClass.self as! T.Type),
        [("float", \MyFinalClass.float), ("int", \MyFinalClass.int)])
    }
    test(erasingAs: Any.self)
    test(erasingAs: MyProtocol.self)
  }
}


//final class KeyPathReflectionTests: XCTestCase {
//  func testStoredPropertyKeyPaths() throws {
//    try StoredPropertyKeyPaths.testMyStruct()
////    try StoredPropertyKeyPaths.testClass()
////    try StoredPropertyKeyPaths.testExistential()
//  }
//
//  func testCustomKeyPaths() throws {
//    try CustomKeyPaths.testOptional()
////    try CustomKeyPaths.testMyStruct()
////    try CustomKeyPaths.testExistential()
////    try CustomKeyPaths.testClass()
////    try CustomKeyPaths.testArray()
//  }
//}
