#!/bin/zsh
# Builds SnapshotTesting.xcframework (Release, library evolution on) for iOS, iOS Simulator and
# macOS from a branch of the swift-snapshot-testing fork, zips it as
# SnapshotTesting-<VERSION>.xcframework.zip, and points Package.swift at that zip's GitHub release
# download URL and checksum.
#
# Usage: VERSION=1.19.6-8byte.1 REF=perf/byte-diff-2-uint64-words Scripts/build-xcframework.sh
#   VERSION  Release tag: <upstream version>-<variant>.<build>, e.g. 1.19.6-8byte.1 (required).
#   REF      Branch of the fork to build (default: perf/byte-diff-2-uint64-words).
#   XCODE    Xcode to build with (default: /Applications/Xcode.app). Build with the OLDEST Xcode
#            consumers use: a framework built by a newer Swift compiler may not load in an older one.
#   SOURCE   Path to the swift-snapshot-testing checkout (default: ../swift-snapshot-testing).
#   REPO     GitHub repository the release is uploaded to
#            (default: ariskox/swift-snapshot-testing-binary).
set -euo pipefail

ROOT=${0:A:h:h}
VERSION=${VERSION:?Set VERSION, e.g. VERSION=1.19.6-8byte.1}
REF=${REF:-perf/byte-diff-2-uint64-words}
XCODE=${XCODE:-/Applications/Xcode.app}
SOURCE=${SOURCE:-$ROOT/../swift-snapshot-testing}
REPO=${REPO:-ariskox/swift-snapshot-testing-binary}
ZIP=SnapshotTesting-$VERSION.xcframework.zip
WORK=$ROOT/.build-xcframework
export DEVELOPER_DIR=$XCODE/Contents/Developer

echo "Building $VERSION from $REF with $(xcodebuild -version | head -1) ($(xcrun swift --version 2>&1 | grep -o 'Swift version [0-9.]*'))"

rm -rf $WORK
mkdir -p $WORK/src
git -C $SOURCE archive $REF | tar -x -C $WORK/src

# Build-only manifest: just the SnapshotTesting library, as a dynamic framework, plus the NEON C
# target on branches that have it (it's linked into the framework).
rm -f $WORK/src/Package@swift-*.swift $WORK/src/Package.resolved
if [[ -d $WORK/src/Sources/SnapshotTestingByteDiff ]]; then
  c_dependencies='dependencies: ["SnapshotTestingByteDiff"]'
  c_target='.target(name: "SnapshotTestingByteDiff"),'
else
  c_dependencies='dependencies: []'
  c_target=''
fi
cat > $WORK/src/Package.swift <<EOF
// swift-tools-version:6.0

import PackageDescription

let package = Package(
  name: "swift-snapshot-testing",
  platforms: [.iOS(.v13), .macOS(.v10_15)],
  products: [
    .library(name: "SnapshotTesting", type: .dynamic, targets: ["SnapshotTesting"])
  ],
  targets: [
    .target(name: "SnapshotTesting", $c_dependencies),
    $c_target
  ],
  swiftLanguageModes: [.v5]
)
EOF

xcframework_args=()
for platform in "iOS" "iOS Simulator" "macOS"; do
  name=${platform// /-}
  archive=$WORK/archives/$name.xcarchive
  echo "Archiving $platform…"
  (cd $WORK/src && xcodebuild archive \
    -scheme swift-snapshot-testing \
    -configuration Release \
    -destination "generic/platform=$platform" \
    -archivePath $archive \
    -derivedDataPath $WORK/dd-$name \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    > $WORK/$name.log 2>&1) || { tail -30 $WORK/$name.log; exit 1; }

  framework=$archive/Products/usr/local/lib/SnapshotTesting.framework
  products=$WORK/dd-$name/Build/Intermediates.noindex/ArchiveIntermediates/swift-snapshot-testing/BuildProductsPath
  module=$(find $products -maxdepth 2 -name SnapshotTesting.swiftmodule -type d | head -1)
  [[ -n $module ]] || { echo "No SnapshotTesting.swiftmodule for $platform"; exit 1; }

  # SwiftPM doesn't copy the Swift module into the framework, so add it (and a module map).
  if [[ $platform == macOS ]]; then
    modules_dir=$framework/Versions/A/Modules
    ln -sfh Versions/Current/Modules $framework/Modules
  else
    modules_dir=$framework/Modules
  fi
  mkdir -p $modules_dir
  cp -R $module $modules_dir/
  cat > $modules_dir/module.modulemap <<'EOF'
framework module SnapshotTesting {
  export *
}
EOF

  # Adding the module invalidated the original signature; re-sign ad hoc. Consumers' Xcode
  # re-signs embedded frameworks with their own identity.
  codesign --force --sign - $framework > /dev/null 2>&1

  xcframework_args+=(-framework $framework)
  dsym=$archive/dSYMs/SnapshotTesting.framework.dSYM
  [[ -d $dsym ]] && xcframework_args+=(-debug-symbols $dsym)
done

rm -rf $ROOT/SnapshotTesting.xcframework $ROOT/SnapshotTesting*.xcframework.zip
xcodebuild -create-xcframework $xcframework_args -output $ROOT/SnapshotTesting.xcframework

(cd $ROOT && ditto -c -k --keepParent SnapshotTesting.xcframework $ZIP)
checksum=$(cd $ROOT && swift package compute-checksum $ZIP)

cat > $ROOT/Package.swift <<EOF
// swift-tools-version:5.9

import PackageDescription

let package = Package(
  name: "SnapshotTestingBinary",
  platforms: [.iOS(.v13), .macOS(.v10_15)],
  products: [
    .library(name: "SnapshotTesting", targets: ["SnapshotTesting"])
  ],
  targets: [
    // $VERSION: Release build of $REF, made by Scripts/build-xcframework.sh.
    .binaryTarget(
      name: "SnapshotTesting",
      url: "https://github.com/$REPO/releases/download/$VERSION/$ZIP",
      checksum: "$checksum"
    )
  ]
)
EOF

cat > $ROOT/BUILD_INFO.txt <<EOF
version: $VERSION
ref: $REF ($(git -C $SOURCE rev-parse --short $REF))
xcode: $(xcodebuild -version | tr '\n' ' ')
swift: $(xcrun swift --version 2>&1 | head -1)
asset: $ZIP
checksum: $checksum
EOF
cat $ROOT/BUILD_INFO.txt
