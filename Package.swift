// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "YambCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "YambCore", targets: ["YambCore"]),
    ],
    targets: [
        .target(name: "YambCore"),
        // Plain executable test runner, so the rules can be checked without Xcode.
        // Run with ./run-checks.sh
        .executableTarget(name: "YambChecks", dependencies: ["YambCore"]),
    ]
)
