// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OAuth",
    platforms: [.iOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "OAuth",
            targets: ["OAuth"]),
    ],
    dependencies: [
        .package(url: "https://github.com/okta/okta-oidc-ios.git", .upToNextMinor(from: "3.11.2")),
        .package(url: "https://github.com/CruGlobal/request-operation-ios.git", .upToNextMinor(from: "1.3.2")),
        .package(url: "https://github.com/CruGlobal/keychain-password-store-ios.git", .upToNextMinor(from: "1.0.3"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "OAuth",
            dependencies: [
                .product(name: "OktaOidc", package: "okta-oidc-ios"),
                .product(name: "RequestOperation", package: "request-operation-ios"),
                .product(name: "KeychainPasswordStore", package: "keychain-password-store-ios")
            ],
            exclude: ["../../Example"]),
        .testTarget(
            name: "OAuthTests",
            dependencies: ["OAuth"]),
    ]
)
