# String initializers with encoding validation

* Proposal: [SE-NNNN String initializers with encoding validation](https://gist.github.com/glessard/d1ed79b7968b4ad2115462b3d1eba805)
* Author: [Guillaume Lessard](https://github.com/glessard)
* Review Manager: TBD
* Status: Pitch
* Bugs: rdar://99276048, rdar://99832858
* Implementation: [Staged package](https://github.com/apple/swift-evolution-staging/tree/input-validating-string-initializers)
* Review: ([pitch](https://forums.swift.org/t/66206))
* Previous Revision: ([0](https://gist.github.com/glessard/d1ed79b7968b4ad2115462b3d1eba805))

## Introduction

We propose adding new `String` failable initializers that validate encoded input, and return `nil` when the input contains any invalid elements.

## Motivation

The `String` type guarantees that it represents well-formed Unicode text. When data representing text is received from a file, the network, or some other source, it may be relevant to store it in a `String`, but that data must be validated first. `String` already provides a way to transform data to valid Unicode by repairing invalid elements, but such a transformation is often not desirable, especially when dealing with untrusted sources. For example a JSON decoder cannot transform its input; it must fail if a span representing text contains any invalid UTF-8.

This functionality has not been available directly from the standard library. It is possible to compose it using existing public API, but only at the cost of extra memory copies and allocations. The standard library is uniquely positioned to implement this functionality in a performant way.

## Proposed Solution

We will add a new `String` initializer that can fail, returning `nil`, when its input is found to be invalid according the encoding represented by a type parameter that conforms to `Unicode.Encoding`.

```swift
extension String {
  public init?<Encoding: Unicode.Encoding>(
  	validating codeUnits: some Sequence<Encoding.CodeUnit>, as: Encoding.Type
  )
}
```

For convenience and discoverability for the most common case, we will also provide an initializer that specifies the UTF-8 input encoding as part of its argument label:

```swift
extension String {
  public init?(validatingAsUTF8 codeUnits: some Sequence<UTF8.CodeUnit>)
}
```

This will construct a new `String`, returning `nil` when the input is found invalid according to the UTF-8 encoding.

When processing data obtained from C, it is frequently the case that UTF-8 data is represented by `CChar` rather than `UInt8`. We will provide a convenience initializer for this use case. Noting that this situation typically involves contiguous memory, we believe it will be well-served by explicitly using an abstraction for contiguous memory (`UnsafeBufferPointer<CChar>`):

```swift
extension String {
  public init?(validatingAsUTF8 codeUnits: UnsafeBufferPointer<CChar>)
}
```

The `String.init(validatingAsUTF8:)` functions convert their whole input, including any embedded `\0` code units.

`String` already features a validating initializer for UTF-8 input, though it is intended for C interoperability.  Its argument label does not convey the expectation that its input is a null-terminated C string, and this has caused errors. We propose to change the labels in order to clarify the preconditions:

```swift
extension String {
  public init?(validatingCString nullTerminatedUTF8: UnsafePointer<CChar>)

  @available(Swift 5.XLIX, deprecated, renamed:"String.init(validatingCString:)")
  public init?(validatingUTF8 cString: UnsafePointer<CChar>)
}
```

## Detailed Design

We want these new initializers to be performant. As such, their implementation should minimize the number of memory allocations and copies required. We achieve this performance with `@inlinable` implementations that leverage `withContiguousStorageIfAvailable` to provide a concrete (`internal`) code path for the validation cases. The concrete `internal` initializer itself calls a number of functions internal to the standard library.

```swift
extension String {
  /// Create a new `String` by copying and validating the sequence of
  /// code units passed in, according to the specified encoding.
  ///
  /// This initializer does not try to repair ill-formed code unit sequences.
  /// If any are found, the result of the initializer is `nil`.
  ///
  /// The following example calls this initializer with the contents of two
  /// different arrays---first with a well-formed UTF-8 code unit sequence and
  /// then with an ill-formed UTF-16 code unit sequence.
  ///
  ///     let validUTF8: [UInt8] = [67, 97, 102, 195, 169]
  ///     let valid = String(validating: validUTF8, as: UTF8.self)
  ///     print(valid)
  ///     // Prints "Optional("Café")"
  ///
  ///     let invalidUTF16: [UInt16] = [0x41, 0x42, 0xd801]
  ///     let invalid = String(validating: invalidUTF16, as: UTF16.self)
  ///     print(invalid)
  ///     // Prints "nil"
  ///
  /// - Parameters
  ///   - codeUnits: A sequence of code units that encode a `String`
  ///   - encoding: An implementation of `Unicode.Encoding` that should be used
  ///               to decode `codeUnits`.
  @inlinable
  public init?<Encoding>(
    validating codeUnits: some Sequence<Encoding.CodeUnit>, as: Encoding.Type
  ) where Encoding: Unicode.Encoding
}
```

```swift
extension String {
  /// Create a new `String` by copying and validating the sequence of
  /// UTF-8 code units passed in.
  ///
  /// This initializer does not try to repair ill-formed code unit sequences.
  /// If any are found, the result of the initializer is `nil`.
  ///
  /// The following example calls this initializer with the contents of two
  /// different arrays---first with a well-formed UTF-8 code unit sequence and
  /// then with an ill-formed code unit sequence.
  ///
  ///     let validUTF8: [UInt8] = [67, 97, 102, 195, 169]
  ///     let valid = String(validatingAsUTF8: validUTF8)
  ///     print(valid)
  ///     // Prints "Optional("Café")"
  ///
  ///     let invalidUTF8: [UInt8] = [67, 195, 0]
  ///     let invalid = String(validatingAsUTF8: invalidUTF8)
  ///     print(invalid)
  ///     // Prints "nil"
  ///
  /// Note: This initializer is functionally equivalent to using
  ///       `String(validating: some Sequence<UTF8.CodeUnit>, as: UTF8.self)`.
  ///
  /// - Parameters
  ///   - codeUnits: A sequence of code units that encode a `String`
  public init?(validatingAsUTF8 codeUnits: some Sequence<UTF8.CodeUnit>)
}
```

```swift
extension String {
  /// Create a new `String` by copying and validating the sequence of `CChar`
  /// passed in, by interpreting them as UTF-8 code units.
  ///
  /// This initializer does not try to repair ill-formed code unit sequences.
  /// If any are found, the result of the initializer is `nil`.
  ///
  /// The following example calls this initializer with the contents of two
  /// different `CChar` arrays---first with a well-formed UTF-8
  /// code unit sequence and then with an ill-formed code unit sequence.
  ///
  ///     let validUTF8: [CChar] = [67, 97, 0, 102, -61, -87]
  ///     validUTF8.withUnsafeBufferPointer {
  ///         let s = String(validatingAsUTF8: $0)
  ///         print(s)
  ///     }
  ///     // Prints "Optional("Café")"
  ///
  ///     let invalidUTF8: [CChar] = [67, -61, 0]
  ///     invalidUTF8.withUnsafeBufferPointer {
  ///         let s = String(validatingAsUTF8: $0)
  ///         print(s)
  ///     }
  ///     // Prints "nil"
  ///
  /// - Parameters
  ///   - codeUnits: A sequence of code units that encode a `String`
  public init?(validatingAsUTF8 codeUnits: UnsafeBufferPointer<CChar>)
}
```

```swift
extension String {
  /// Create a new string by copying and validating the null-terminated UTF-8
  /// data referenced by the given pointer.
  ///
  /// This initializer does not try to repair ill-formed UTF-8 code unit
  /// sequences. If any are found, the result of the initializer is `nil`.
  ///
  /// The following example calls this initializer with pointers to the
  /// contents of two different `CChar` arrays---first with well-formed
  /// UTF-8 code unit sequences and the second with an ill-formed sequence at
  /// the end.
  ///
  ///     let validUTF8: [CChar] = [67, 97, 102, -61, -87, 0]
  ///     validUTF8.withUnsafeBufferPointer { ptr in
  ///         let s = String(validatingUTF8: ptr.baseAddress!)
  ///         print(s)
  ///     }
  ///     // Prints "Optional("Café")"
  ///
  ///     let invalidUTF8: [CChar] = [67, 97, 102, -61, 0]
  ///     invalidUTF8.withUnsafeBufferPointer { ptr in
  ///         let s = String(validatingUTF8: ptr.baseAddress!)
  ///         print(s)
  ///     }
  ///     // Prints "nil"
  ///
  /// - Parameter cString: A pointer to a null-terminated UTF-8 code sequence.
  @_silgen_name("sSS14validatingUTF8SSSgSPys4Int8VG_tcfC")
  public init?(validatingCString nullTerminatedCodeUnits: UnsafePointer<CChar>)
  
  @available(Swift 5.XLIX, deprecated, renamed:"String.init(validatingCString:)")
  @_silgen_name("_swift_stdlib_legacy_String_validatingUTF8")
  @_alwaysEmitIntoClient
  public init?(validatingUTF8 cString: UnsafePointer<CChar>)
}
```

## Source Compatibility

This proposal is strictly additive.

## ABI Compatibility

This proposal adds new functions to the ABI.

## Implications on adoption

This feature requires a new version of the standard library.

## Alternatives considered

#### The `validatingAsUTF8` argument label

The argument label `validatingUTF8` seems like it may have been preferable to `validatingAsUTF8`, but using the former would have been source-breaking. The C string validation initializer takes an `UnsafePointer<UInt8>`, but it can also accept `[UInt8]` via implicit pointer conversion. Any use site that passes an `[UInt8]` to the C string validation initializer would have changed behaviour upon recompilation, from considering a null character (`\0`) as the termination of the C string to considering it as a valid, non-terminating character.

#### Have the `CChar`-validating function take a parameter of type `some Sequence<CChar>`

This would produce a compile-time ambiguity on platforms where `CChar` is typealiased to `UInt8` rather than `Int8`. Using `UnsafeBufferPointer<CChar>` as the parameter type will avoid such a compile-time ambiguity.

## Future directions

#### Throw an error containing information about a validation failure

When decoding a byte stream, obtaining the details of a validation failure would be useful in order to diagnose issues. We would like to provide this functionality, but the current input validation functionality is not well-suited for it. This is left as a future improvement.

#### Improve input-repairing initialization

There is only one initializer in the standard library for input-repairing initilization, and it suffers from a discoverability issue. We can add a more discoverable version specifically for the UTF-8 encoding, similarly to one of the additions proposed here.

#### Add normalization options

It is often desirable to normalize strings, but the standard library does not expose public API for doing so. We could add initializers that perform normalization, as well as mutating functions that perform normalization.

#### Other

- Add a (non-failable) initializer to create a `String` from `some Sequence<UnicodeScalar>`.
- Add API devoted to input validation specifically.

## Acknowledgements

Thanks to Michael Ilseman, Tina Liu and Quinn Quinn for discussions about input validation issues.

[SE-0027](https://github.com/apple/swift-evolution/blob/main/proposals/0027-string-from-code-units.md) by [Zachary Waldowski](https://github.com/zwaldowski) was reviewed in February 2016, covering similar ground. It was rejected at the time because the design of `String` had not been finalized. The name `String.init(validatingCString:)` was suggested as part of SE-0027. Lily Ballard later [pitched](https://forums.swift.org/t/21538) a renaming of `String.init(validatingUTF8:)`, citing consistency with other `String` API involving C strings.

