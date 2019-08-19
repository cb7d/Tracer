// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
        name: "Tracer",
        dependencies: [
                // Dependencies declare other packages that this package depends on.
                .package(url: "https://github.com/thoughtbot/Curry", from: "4.0.2"),
                .package(url: "https://github.com/kylef/Commander", from: "0.9.0"),
//                .package(url: "https://github.com/FelixScat/Parser", from: "0.0.1"),
                // .package(url: "https://github.com/FelixScat/LLexer", from: "0.0.1"),
                 .package(path: "../Parser"),
                 .package(path: "../LLexer"),
        ],
        targets: [
                // Targets are the basic building blocks of a package. A target can define a module or a test suite.
                // Targets can depend on other targets in this package, and on products in packages which this package depends on.
                .target(
                        name: "Tracer",
                        dependencies: ["Curry", "Commander", "Parser", "LLexer"]
                ),
                .testTarget(
                        name: "TracerTests",
                        dependencies: ["Tracer"]
                ),
        ]
)
