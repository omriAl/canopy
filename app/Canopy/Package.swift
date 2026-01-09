// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Canopy",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Canopy", targets: ["Canopy"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Canopy",
            dependencies: [],
            path: "Sources/Canopy"
        )
    ]
)
