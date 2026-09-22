// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LetsActCore",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [.library(name: "LetsActCore", targets: ["LetsActCore"])],
    targets: [
        .target(name: "LetsActCore", path: "ios/LetsAct/Core"),
        .testTarget(name: "LetsActCoreTests", dependencies: ["LetsActCore"], path: "Tests/LetsActCoreTests")
    ]
)
