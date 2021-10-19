// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KeychainHanger",
    products: [
        .library(
            name: "KeychainHanger",
            targets: ["KeychainHanger"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "KeychainHanger",
            dependencies: []),
        .testTarget(
            name: "KeychainHangerTests",
            dependencies: ["KeychainHanger"]),
    ]
)
