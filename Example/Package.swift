// swift-tools-version:5.9

import Foundation
import PackageDescription

// SNAPSHOT_TESTING_SOURCE=<path> builds against a source checkout instead, for comparison.
let source = ProcessInfo.processInfo.environment["SNAPSHOT_TESTING_SOURCE"]
// A path dependency's package name is its folder name.
let snapshotTestingPackage = URL(
  fileURLWithPath: source ?? URL(fileURLWithPath: Context.packageDirectory).deletingLastPathComponent().path
).lastPathComponent

// Consumes the binary SnapshotTesting package the way an app's test target would.
let package = Package(
  name: "Example",
  platforms: [.iOS(.v13), .macOS(.v10_15)],
  products: [.library(name: "Example", targets: ["Example"])],
  dependencies: [.package(path: source ?? "..")],
  targets: [
    .target(name: "Example"),
    .testTarget(
      name: "ExampleTests",
      dependencies: [
        "Example",
        .product(
          name: "SnapshotTesting",
          package: snapshotTestingPackage
        ),
      ]
    ),
  ]
)
