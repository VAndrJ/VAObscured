// swift-tools-version: 5.9

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "VAObscured",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .tvOS(.v15),
        .watchOS(.v8),
        .macCatalyst(.v15),
    ],
    products: [
        .library(
            name: "VAObscured",
            targets: ["VAObscured"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0")
    ],
    targets: [
        .macro(
            name: "VAObscuredMacros",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
            ]
        ),
        .target(name: "VAObscured", dependencies: ["VAObscuredMacros"]),
        .executableTarget(name: "VAObscuredClient", dependencies: ["VAObscured"]),
        .executableTarget(
            name: "VAObscuredBinaryCheck",
            dependencies: ["VAObscured"],
            path: "Tests/Fixtures/VAObscuredBinaryCheck"
        ),
        .target(
            name: "VAObscuredConsumer",
            dependencies: ["VAObscured"],
            path: "Tests/Fixtures/VAObscuredConsumer"
        ),
        .testTarget(
            name: "VAObscuredTests",
            dependencies: [
                "VAObscured",
                "VAObscuredConsumer",
                "VAObscuredMacros",
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacroExpansion", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
