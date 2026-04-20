// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MOBIRendererPrimitive",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "MOBIRendererPrimitive",
            targets: ["MOBIRendererPrimitive"]
        ),
    ],
    dependencies: [
        .package(path: "../ContentModelPrimitive"),
        .package(path: "../PreviewPrimitive"),
    ],
    targets: [
        .target(
            name: "MOBIRendererPrimitive",
            dependencies: [
                .product(name: "ContentModelPrimitive", package: "ContentModelPrimitive"),
                .product(name: "FilePreviewPrimitiveHTML", package: "PreviewPrimitive"),
            ],
            path: "Sources/MOBIRendererPrimitive"
        ),
        .testTarget(
            name: "MOBIRendererPrimitiveTests",
            dependencies: ["MOBIRendererPrimitive"],
            path: "Tests/MOBIRendererPrimitiveTests"
        ),
    ]
)
