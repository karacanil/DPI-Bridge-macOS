// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DPI-Bridge-macOS",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "DPI-Bridge",
            targets: ["DPIBridge"]
        ),
        .executable(
            name: "discord-http-proxy",
            targets: ["DiscordHTTPProxy"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "DPIBridge",
            dependencies: [],
            path: "Sources/DPIBridge"
        ),
        .executableTarget(
            name: "DiscordHTTPProxy",
            path: "Sources/DiscordHTTPProxy"
        )
    ]
)
