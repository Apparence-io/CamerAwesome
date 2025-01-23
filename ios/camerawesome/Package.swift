// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "camerawesome",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(name: "camerawesome", targets: ["camerawesome"])
    ],
    dependencies: [

    ],
    targets: [
        .target(
            name: "camerawesome",
            dependencies: [],
            resources: [],
            publicHeadersPath: "",
            cSettings: [
                .headerSearchPath("include")
            ]
        )
    ]
)

