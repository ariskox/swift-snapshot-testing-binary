# swift-snapshot-testing-binary

Precompiled, Release-mode builds of `SnapshotTesting` with faster image comparison, shipped as a
Swift package with a binary target, for iOS (device and simulator) and macOS.

**This is an unofficial build** of a modified fork
([ariskox/swift-snapshot-testing](https://github.com/ariskox/swift-snapshot-testing)) of
[pointfreeco/swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing). It
isn't made or supported by Point-Free. The original code is MIT-licensed; see [LICENSE](LICENSE).

## Variants

Each release tag is `<upstream version>-<variant>.<build>`. Every variant has the same public API
as upstream `SnapshotTesting`; they differ only in how image comparisons with `precision < 1` count
differing bytes.

| Variant | Tag | Fork branch | Technique |
|---|---|---|---|
| **8byte** | `1.19.6-8byte.1` | `perf/byte-diff-2-uint64-words` | Compares 8 bytes per step, in Swift |
| rawptr | *not released yet* | `perf/byte-diff-1-raw-pointers` | Reads buffers through raw pointers |
| neon | *not released yet* | `perf/byte-diff-3-neon` | NEON vector instructions on arm64 |

Full image diff (`Diffing.image(precision: 0.99)`, 1179×2556 image) from a Debug test target, median
of 10 runs:

| What the test target links | iOS simulator | macOS |
|---|---|---|
| Upstream 1.19.6 from source | 116.8 ms | 54.9 ms |
| 8byte branch from source | 40.1 ms | 31.2 ms |
| **8byte binary (this package)** | **15.2 ms** | **21.7 ms** |

The binary links into Debug test targets: its code stays optimized while your tests stay
debuggable.

## Use it

Versions with a `-variant` suffix are pre-releases in semantic versioning, so `from:` ranges don't
select them. Pin the exact tag instead:

```swift
.package(url: "https://github.com/ariskox/swift-snapshot-testing-binary", exact: "1.19.6-8byte.1"),
...
.testTarget(
  name: "MyAppTests",
  dependencies: [.product(name: "SnapshotTesting", package: "swift-snapshot-testing-binary")]
)
```

- Depend on it from **test targets only**; the framework links XCTest.
- `InlineSnapshotTesting` and `SnapshotTestingCustomDump` aren't included.
- Don't also depend on upstream `swift-snapshot-testing` in the same target; both provide a module
  named `SnapshotTesting`.

## Xcode compatibility

Each release's notes say which Xcode built it. A framework built with a newer Swift compiler may
not load in an older Xcode, so a build only works in that Xcode version or newer.
`1.19.6-8byte.1` was built with **Xcode 27.1**; an Xcode 26.6 build will follow as a new
`.<build>` number.

## Build a release

```sh
VERSION=1.19.6-8byte.2 REF=perf/byte-diff-2-uint64-words XCODE=/Applications/Xcode26.app \
  Scripts/build-xcframework.sh
```

The script builds the fork's branch at `../swift-snapshot-testing` (change it with `SOURCE`) and
zips the framework as `SnapshotTesting-<VERSION>.xcframework.zip`. It also points `Package.swift`
at that zip's release URL and checksum, and writes `BUILD_INFO.txt`. Then commit, tag `VERSION`,
and upload the zip to a GitHub release with the same tag.

## Example

`Example/` is a consumer package with a Debug test target. It checks that precision failures are
still reported, that `assertSnapshot` records and compares, and it times a full image diff:

```sh
cd Example && swift test
```

To compare against a source checkout built in Debug instead:

```sh
SNAPSHOT_TESTING_SOURCE=/path/to/swift-snapshot-testing swift test
```
