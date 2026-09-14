// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacExplorer",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "MacExplorer", targets: ["MacExplorer"])],
    targets: [
        .target(name: "ExplorerCore", resources: [.process("Resources")]),
        .executableTarget(name: "MacExplorer", dependencies: ["ExplorerCore"]),
        .executableTarget(name: "MacExplorerCoreChecks", dependencies: ["ExplorerCore"], path: "Tests/ExplorerCoreTests")
    ]
)
