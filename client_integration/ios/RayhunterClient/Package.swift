// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RayhunterClient",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "RayhunterClient",
            targets: ["RayhunterClient"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.1"),
    ],
    targets: [
        .target(
            name: "RayhunterClient",
            dependencies: ["Alamofire"]),
        .testTarget(
            name: "RayhunterClientTests",
            dependencies: ["RayhunterClient"]),
    ]
) 