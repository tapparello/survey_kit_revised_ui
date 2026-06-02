// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "survey_kit",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "survey-kit", targets: ["survey_kit"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "survey_kit",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
