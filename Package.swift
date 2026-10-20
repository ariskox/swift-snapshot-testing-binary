// swift-tools-version:5.9

import PackageDescription

let package = Package(
  name: "SnapshotTestingBinary",
  platforms: [.iOS(.v13), .macOS(.v10_15)],
  products: [
    .library(name: "SnapshotTesting", targets: ["SnapshotTesting"])
  ],
  targets: [
    // 1.19.6-8byte.1: Release build of perf/byte-diff-2-uint64-words, made by Scripts/build-xcframework.sh.
    .binaryTarget(
      name: "SnapshotTesting",
      url: "https://github.com/ariskox/swift-snapshot-testing-binary/releases/download/1.19.6-8byte.1/SnapshotTesting-1.19.6-8byte.1.xcframework.zip",
      checksum: "85a7ad300512dea197c6d8e958515c612819b1de806bfb0890105e1cee334d18"
    )
  ]
)
