// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BooleanAlgebra",
    dependencies: [
        .package(url: "https://github.com/LuizZak/MiniLexer.git", branch: "master"),
    ],
    targets: [
        .target(
            name: "BooleanAlgebra",
            dependencies: [
                .product(name: "MiniLexer", package: "MiniLexer"),
            ]
        ),
        // Tests
        .testTarget(
            name: "BooleanAlgebraTests",
            dependencies: ["BooleanAlgebra"]
        )
    ]
)
