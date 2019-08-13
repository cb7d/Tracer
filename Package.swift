// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
        name: "Tracer",
        dependencies: [
                // Dependencies declare other packages that this package depends on.
                // .package(url: /* package url */, from: "1.0.0"),
//        .package(url: "https://github.com/kylef/PathKit.git", from: "0.9.1"),
//        .package(url: "https://github.com/L-Zephyr/SwiftyParse.git", from: "0.1.0"),
                .package(url: "https://github.com/thoughtbot/Curry", from: "4.0.2"),
                .package(url: "https://github.com/kylef/Commander", from: "0.9.0"),
//                .package(path: "../LLexer"),
                .package(path: "../LLexer"),
                .package(path: "../Parser"),
        ],
        targets: [
                // Targets are the basic building blocks of a package. A target can define a module or a test suite.
                // Targets can depend on other targets in this package, and on products in packages which this package depends on.
                .target(
                        name: "Tracer",
                        dependencies: ["Curry", "Commander", "LLexer", "Parser"]
                ),
                //        "SwiftyParse", "PathKit"
                .testTarget(
                        name: "TracerTests",
                        dependencies: ["Tracer"]
                ),
        ]
)
