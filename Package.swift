// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MOBIRendererPrimitive",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "MOBIRendererPrimitive",
            targets: ["MOBIRendererPrimitive"]
        ),
    ],
    dependencies: [
        .package(path: "../ContentModelPrimitive"),
        .package(path: "../HTMLRendererPrimitive"),
    ],
    targets: [
        .target(
            name: "MOBIRendererPrimitive",
            dependencies: [
                .product(name: "ContentModelPrimitive", package: "ContentModelPrimitive"),
                .product(name: "HTMLRendererPrimitive", package: "HTMLRendererPrimitive"),
            ],
            path: "Sources/MOBIRendererPrimitive",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "MOBIRendererPrimitiveTests",
            dependencies: ["MOBIRendererPrimitive"],
            path: "Tests/MOBIRendererPrimitiveTests"
        ),
    ]
)
