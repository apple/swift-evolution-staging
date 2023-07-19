// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SEnnnn_inputValidatingStringInitializers",
    platforms: [.macOS(.v14)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SE0000inputValidatingStringInitializers",
            targets: ["SE0000inputValidatingStringInitializers"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SE0000inputValidatingStringInitializers",
            swiftSettings: [
              .unsafeFlags(
                [
                  "-Xfrontend", "-disable-access-control", "-enable-builtin-module"
                ],
                .when(platforms: [.macOS])
              )
            ]
        ),
        .testTarget(
            name: "SE0000inputValidatingStringInitializerTests",
            dependencies: ["SE0000inputValidatingStringInitializers"]),
    ]
)
