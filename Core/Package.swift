// swift-tools-version: 5.9

import PackageDescription

private let packageDependencies: [Package.Dependency] = [
    .package(
        url: "https://github.com/pointfreeco/swift-composable-architecture",
        from: "1.19.0"
    ),
    .package(
        url: "https://github.com/pointfreeco/swift-snapshot-testing",
        from: "1.18.3"
    ),
    .package(
        url: "https://github.com/marmelroy/PhoneNumberKit",
        exact: "3.7.0"
    ),
    .package(
        url: "https://github.com/SDWebImage/SDWebImageSwiftUI",
        exact: "3.1.3"
    ),
    .package(url: "https://github.com/mercari/ShimmerView.git", .upToNextMajor(from: "0.5.1")),
]

private let tcaDependency: Target.Dependency = .product(
    name: "ComposableArchitecture",
    package: "swift-composable-architecture"
)

private let snapshotTestingDependency: Target.Dependency = .product(
    name: "SnapshotTesting",
    package: "swift-snapshot-testing"
)

private let phoneNumberDependency: Target.Dependency = .product(
    name: "PhoneNumberKit",
    package: "PhoneNumberKit"
)

private let sdWebImageDependency: Target.Dependency = .product(
    name: "SDWebImageSwiftUI",
    package: "SDWebImageSwiftUI"
)

private let swiftSettings: [SwiftSetting] = [
    .define("SWIFT_PACKAGE")
]

private let products: [Product] = [
    .library(
        name: "Core",
        targets: ["Core"]
    )
]

private let shimmerDependency: Target.Dependency = .product(
    name: "ShimmerView",
    package: "ShimmerView"
)

let package = Package(
    name: "Core",
    defaultLocalization: "en",
    platforms: [
        .iOS("16.7")
    ],
    products: products,
    dependencies: packageDependencies,
    targets: [
        .target(
            name: "Core",
            dependencies: [
                tcaDependency,
                phoneNumberDependency,
                sdWebImageDependency,
                shimmerDependency
            ],
            resources: [
                .process("Resources/Colors.xcassets"),
                .process("Resources/DINNextLTArabic.xcassets"),
                .process("Resources/Icons.xcassets"),
                .process("Resources/Countries.json"),
                .process("Resources/Flags.xcassets")
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "SnapShotTests",
            dependencies: [
                "Core",
                snapshotTestingDependency
            ]
        )
    ]
)
