// swift-tools-version:5.9

import PackageDescription

let package = Package(
  name: "SnapshotTestingBinary",
  platforms: [.iOS(.v13), .macOS(.v10_15)],
  products: [
    .library(name: "SnapshotTesting", targets: ["SnapshotTesting"])
  ],
  targets: [
    // 1.19.6-neon.1: Release build of perf/byte-diff-3-neon, made by Scripts/build-xcframework.sh.
    .binaryTarget(
      name: "SnapshotTesting",
      url: "https://github.com/ariskox/swift-snapshot-testing-binary/releases/download/1.19.6-neon.1/SnapshotTesting-1.19.6-neon.1.xcframework.zip",
      checksum: "56dded01558a00f7f5ad70cb1a31142aee12da88856a7309cb1e64ad0fc3e18c"
    )
  ]
)
