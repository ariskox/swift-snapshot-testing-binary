// swift-tools-version:5.9

import PackageDescription

let package = Package(
  name: "SnapshotTestingBinary",
  platforms: [.iOS(.v13), .macOS(.v10_15)],
  products: [
    .library(name: "SnapshotTesting", targets: ["SnapshotTesting"])
  ],
  targets: [
    // 1.19.6-rawptr.1: Release build of perf/byte-diff-1-raw-pointers, made by Scripts/build-xcframework.sh.
    .binaryTarget(
      name: "SnapshotTesting",
      url: "https://github.com/ariskox/swift-snapshot-testing-binary/releases/download/1.19.6-rawptr.1/SnapshotTesting-1.19.6-rawptr.1.xcframework.zip",
      checksum: "23901ad9d1463866021e5280c4dd1f1bacb2868ff70b940311c62bd6679efd03"
    )
  ]
)
