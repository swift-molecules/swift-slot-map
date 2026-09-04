// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-slot-map",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [

        .library(name: "SlotMap Primitive", targets: ["SlotMap Primitive"]),

        .library(name: "SlotMap", targets: ["SlotMap"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-molecules/swift-storage-generational.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-storage.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-ownership-shared.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-buffer.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-memory.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-memory-allocation.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-index.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-ordinal.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-tagged.git",
            branch: "main"
        ),
    ],
    targets: [

        .target(
            name: "SlotMap Primitive",
            dependencies: [
                .product(
                    name: "Storage Generational",
                    package: "swift-storage-generational"
                ),
                .product(name: "Storage Primitive", package: "swift-storage"),
                .product(name: "Store Primitive", package: "swift-storage"),
                .product(name: "Store Protocol", package: "swift-storage"),
                .product(name: "Buffer Protocol", package: "swift-buffer"),
                .product(
                    name: "Ownership Shared Primitive",
                    package: "swift-ownership-shared"
                ),
                .product(name: "Memory", package: "swift-memory"),
                .product(
                    name: "Memory Allocator Primitive",
                    package: "swift-memory-allocation"
                ),
                .product(name: "Index", package: "swift-index"),
            ]
        ),

        .target(
            name: "SlotMap",
            dependencies: [
                "SlotMap Primitive",
                .product(
                    name: "Storage Generational",
                    package: "swift-storage-generational"
                ),
                .product(name: "Storage Primitive", package: "swift-storage"),
                .product(name: "Store Primitive", package: "swift-storage"),
                .product(name: "Store Protocol", package: "swift-storage"),
                .product(name: "Buffer Protocol", package: "swift-buffer"),
                .product(
                    name: "Ownership Shared Primitive",
                    package: "swift-ownership-shared"
                ),
                .product(name: "Memory", package: "swift-memory"),
                .product(
                    name: "Memory Allocator Primitive",
                    package: "swift-memory-allocation"
                ),
                .product(name: "Index", package: "swift-index"),
                .product(
                    name: "Ordinal Standard Library Integration",
                    package: "swift-ordinal"
                ),
            ]
        ),

        .testTarget(
            name: "SlotMap Tests",
            dependencies: [
                "SlotMap",
                .product(
                    name: "Buffer Test Support",
                    package: "swift-buffer"
                ),
                .product(
                    name: "Tagged Standard Library Integration",
                    package: "swift-tagged"
                ),
                .product(
                    name: "Ordinal Standard Library Integration",
                    package: "swift-ordinal"
                ),
                .product(name: "Index", package: "swift-index"),
                .product(
                    name: "Memory Allocator Primitive",
                    package: "swift-memory-allocation"
                ),
                .product(name: "Memory", package: "swift-memory"),
                .product(
                    name: "Ownership Shared Primitive",
                    package: "swift-ownership-shared"
                ),
                .product(
                    name: "Storage Generational",
                    package: "swift-storage-generational"
                ),
                .product(name: "Storage Primitive", package: "swift-storage"),
                .product(name: "Store Primitive", package: "swift-storage"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem
}
