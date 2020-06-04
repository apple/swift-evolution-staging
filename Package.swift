// swift-tools-version:5.1
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

import PackageDescription

let package = Package(
  name: "SE0000_AdjacentPairs",
  products: [
    .library(
      name: "SE0000_AdjacentPairs",
      targets: ["SE0000_AdjacentPairs"]),
  ],
  dependencies: [
  ],
  targets: [
    .target(
      name: "SE0000_AdjacentPairs",
      dependencies: []),
    
    .testTarget(
      name: "SE0000_AdjacentPairsTests",
      dependencies: ["SE0000_AdjacentPairs"]),
  ]
)
