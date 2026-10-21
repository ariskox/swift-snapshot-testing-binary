// swift-tools-version:5.9

import PackageDescription

let package = Package(
  name: "SnapshotTestingBinary",
  platforms: [.iOS(.v13), .macOS(.v10_15)],
  products: [
    .library(name: "SnapshotTesting", targets: ["SnapshotTesting"])
  ],
  targets: [
    // 1.19.6-upstream.1: Release build of 1.19.6, made by Scripts/build-xcframework.sh.
    .binaryTarget(
      name: "SnapshotTesting",
      url: "https://github.com/ariskox/swift-snapshot-testing-binary/releases/download/1.19.6-upstream.1/SnapshotTesting-1.19.6-upstream.1.xcframework.zip",
      checksum: "5e7c941215b65a52a3a1311e5e8a4370d5983a2abaa79414381f58e711cb0a53"
    )
  ]
)
