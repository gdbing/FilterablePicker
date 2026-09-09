// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FilterablePicker",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "FilterablePicker", targets: ["FilterablePicker"])
    ],
    targets: [
        .target(
            name: "FilterablePicker",
            dependencies: ["FilterablePickerAppKit"]
        ),
        .target(
            name: "FilterablePickerAppKit",
            publicHeadersPath: "include"
        ),
        .testTarget(
            name: "FilterablePickerTests",
            dependencies: ["FilterablePicker"]
        ),
    ]
)
