// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "KooberUIKit",
  platforms: [.iOS(.v13)],
  products: [
    // Products define the executables and libraries a package produces, and make them visible to other packages.
    .library(
      name: "KooberUIKit",
      targets: ["KooberUIKit"]),
  ],
  dependencies: [
    .package(path: "KooberKit"),
    .package(url: "https://github.com/mxcl/PromiseKit", .exact("6.16.2")),
    .package(url: "https://github.com/onevcat/Kingfisher.git", .exact("7.1.2")),
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages this package depends on.
    .target(
      name: "KooberUIKit",
      dependencies: ["KooberKit", "PromiseKit", "Kingfisher"]),
    .testTarget(
      name: "KooberUIKitTests",
      dependencies: ["KooberUIKit"]),
  ]
)
