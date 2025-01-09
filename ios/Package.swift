// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "CameraAwesome",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "CameraAwesome",
            targets: ["CameraAwesome"]),
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/JPSVolumeButtonHandler", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "CameraAwesome",
            dependencies: ["JPSVolumeButtonHandler"],
            path: "Classes",
            sources: [
                ".",
                "CameraPreview",
                "Constants",
                "Controllers",
                "Pigeon",
                "Utils"
            ],
            publicHeadersPath: ""
        )
    ]
)
