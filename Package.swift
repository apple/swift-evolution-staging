// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Prototype_CollectionConsumerSearcher",
    products: [
        .library(
            name: "Prototype_CollectionConsumerSearcher",
            targets: ["Prototype_CollectionConsumerSearcher"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ctxppc/PatternKit", .branch("development")),
    ],
    targets: [
        .target(
            name: "CollectionConsumerSearcher",
            dependencies: []),
        .testTarget(
            name: "CollectionConsumerSearcherTests",
            dependencies: ["CollectionConsumerSearcher"]),
        .target(
            name: "Prototype_CollectionConsumerSearcher",
            dependencies: ["CollectionConsumerSearcher", "PatternKit"]),
        .testTarget(
            name: "PrototypeCollectionConsumerSearcherTests",
            dependencies: ["Prototype_CollectionConsumerSearcher"]),
        .target(
            name: "example",
            dependencies: ["Prototype_CollectionConsumerSearcher", "CollectionConsumerSearcher"],
            path: "Sources/Prototype_CollectionConsumerSearcherExample"),
    ]
)
