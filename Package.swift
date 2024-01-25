// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftyEpub",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftyEpub",
            targets: ["SwiftyEpub"]),
    ],
    dependencies: [
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", .upToNextMajor(from: "0.9.0")),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0"),
        .package(url: "https://github.com/tadija/AEXML.git", from: "4.6.1"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.10.0"),
        .package(url: "https://github.com/krzysztofzablocki/Inject.git", from: "1.0.5"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftyEpub",
            dependencies: [
                "ZIPFoundation",
                "SwiftSoup",
                "AEXML",
                "Kingfisher",
                "Inject"
            ],
            resources: [
                .process("HTMLRendering/defaultStyles.css"),
                .process("HTMLRendering/image_213.jpg")
            ]
        ),
        .testTarget(
            name: "SwiftyEpubTests",
            dependencies: ["SwiftyEpub"]),
    ]
)
