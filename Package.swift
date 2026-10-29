// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RARFlow",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "RARFlow", targets: ["RARFlow"])
    ],
    targets: [
        .executableTarget(
            name: "RARFlow",
            path: "Sources/RARFlow"
        ),
        .testTarget(
            name: "RARFlowTests",
            dependencies: ["RARFlow"],
            path: "Tests/RARFlowTests"
        ),
    ]
)
