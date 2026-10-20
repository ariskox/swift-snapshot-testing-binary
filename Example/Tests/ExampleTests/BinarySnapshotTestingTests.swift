import CoreGraphics
import Foundation
import SnapshotTesting
import XCTest

#if os(macOS)
  import AppKit
  typealias PlatformImage = NSImage
#else
  import UIKit
  typealias PlatformImage = UIImage
#endif

final class BinarySnapshotTestingTests: XCTestCase {
  func testPrecisionDiffingFailsAndPasses() {
    let (reference, snapshot) = images(width: 400, height: 300)
    for precision: Float in [1, 0.999, 0.995] {
      XCTAssertNotNil(
        Diffing<PlatformImage>.image(precision: precision).diff(reference, snapshot),
        "precision \(precision)")
    }
    for precision: Float in [0.99, 0.9] {
      XCTAssertNil(
        Diffing<PlatformImage>.image(precision: precision).diff(reference, snapshot),
        "precision \(precision)")
    }
  }

  func testAssertSnapshotRoundTrip() {
    // Records on the first run, then compares against the recorded file.
    withSnapshotTesting(record: .missing) {
      assertSnapshot(of: images(width: 120, height: 80).reference, as: .image)
    }
  }

  func testBenchmarkFullImageDiff() {
    let (reference, snapshot) = images(width: 1179, height: 2556)
    let diffing = Diffing<PlatformImage>.image(precision: 0.99)
    _ = diffing.diff(reference, snapshot)  // Warm up.
    var samples: [Double] = []
    for _ in 0..<10 {
      let start = DispatchTime.now().uptimeNanoseconds
      XCTAssertNil(diffing.diff(reference, snapshot))
      samples.append(Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000)
    }
    samples.sort()
    print(String(format: "[BENCH] full image diff, 1179x2556: median %.2f ms", samples[5]))
  }

  // An image and a copy with a block repainted: 1% of the pixels differ. The reference goes
  // through PNG, as it would when loaded from disk.
  private func images(width: Int, height: Int) -> (reference: PlatformImage, snapshot: PlatformImage) {
    func render(changed: Bool) -> CGImage {
      let context = CGContext(
        data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      )!
      context.setFillColor(CGColor(srgbRed: 0.2, green: 0.6, blue: 0.9, alpha: 1))
      context.fill(CGRect(x: 0, y: 0, width: width, height: height))
      if changed {
        context.setFillColor(CGColor(srgbRed: 0.9, green: 0.1, blue: 0.3, alpha: 1))
        context.fill(CGRect(x: width / 4, y: height / 3, width: width / 10, height: height / 10))
      }
      return context.makeImage()!
    }
    #if os(macOS)
      let size = NSSize(width: width, height: height)
      let reference = NSImage(cgImage: render(changed: false), size: size)
      let snapshot = NSImage(cgImage: render(changed: true), size: size)
    #else
      let reference = UIImage(cgImage: render(changed: false), scale: 1, orientation: .up)
      let snapshot = UIImage(cgImage: render(changed: true), scale: 1, orientation: .up)
    #endif
    let diffing = Diffing<PlatformImage>.image
    return (diffing.fromData(diffing.toData(reference)), snapshot)
  }
}
