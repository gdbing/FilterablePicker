// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FilterablePicker",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "FilterablePicker", targets: ["FilterablePicker"]),
        .executable(name: "FilterablePickerDemo", targets: ["FilterablePickerDemo"])
    ],
    targets: [
        .target(name: "FilterablePicker"),
        .executableTarget(name: "FilterablePickerDemo", dependencies: ["FilterablePicker"]),
        .testTarget(name: "FilterablePickerTests", dependencies: ["FilterablePicker"])
    ]
)
