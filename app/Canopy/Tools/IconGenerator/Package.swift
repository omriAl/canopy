// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "IconGenerator",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "IconGenerator"),
        .executableTarget(name: "DMGBackground")
    ]
)
