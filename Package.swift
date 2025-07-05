// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MorphModalKit",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "MorphModalKit",
            targets: ["MorphModalKit"]
        ),
    ],
    targets: [
        .target(
            name: "MorphModalKit",
            dependencies: [],
            path: "Sources/MorphModalKit"
        ),
    ]
)
