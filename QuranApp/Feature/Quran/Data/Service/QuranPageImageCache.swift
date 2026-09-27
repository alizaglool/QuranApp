//
//  QuranPageImageCache.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 25/09/2026.
//

import UIKit
import ImageIO

// MARK: - QuranPageImageCache

/// Decodes and caches the 15 mushaf line images that make up one Quran page.
///
/// `UIImage(contentsOfFile:)` bypasses UIKit's image cache, so every SwiftUI
/// body pass re-decoded all 15 full-size PNGs (1440x232) on the main thread.
/// This loader decodes once, downsamples to the size actually drawn, keeps the
/// bitmap in an `NSCache`, and warms the neighbouring pages off the main thread.
final class QuranPageImageCache {

    static let shared = QuranPageImageCache()

    /// Lines per mushaf page.
    private static let linesPerPage = 15

    private let cache = NSCache<NSString, UIImage>()

    private let prefetchQueue = DispatchQueue(
        label: "com.wird.quran.page-image-prefetch",
        qos: .utility
    )

    /// Keys currently decoding on `prefetchQueue`, so one line is never
    /// decoded twice concurrently.
    private var inFlight = Set<String>()
    private let inFlightLock = NSLock()

    /// Captured once on the main thread — `UIScreen` must not be read from a
    /// background queue.
    private let screenScale: CGFloat

    private var memoryWarningObserver: NSObjectProtocol?

    private init() {
        screenScale = UIScreen.main.scale

        // Roughly nine pages of lines resident; the cost limit is the real ceiling.
        cache.countLimit = Self.linesPerPage * 9
        cache.totalCostLimit = 96 * 1024 * 1024

        memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.purge()
        }
    }

    deinit {
        if let memoryWarningObserver {
            NotificationCenter.default.removeObserver(memoryWarningObserver)
        }
    }

    // MARK: - Loading

    /// Cached (or freshly decoded) line image, downsampled for a `targetWidth`
    /// point-wide frame. Returns nil when that page/line is not in the bundle.
    func lineImage(page: Int, line: Int, targetWidth: CGFloat) -> UIImage? {
        let maxPixelSize = pixelSize(forTargetWidth: targetWidth)
        let key = cacheKey(page: page, line: line, maxPixelSize: maxPixelSize) as NSString

        if let cached = cache.object(forKey: key) { return cached }

        guard let image = decode(page: page, line: line, maxPixelSize: maxPixelSize) else {
            return nil
        }
        cache.setObject(image, forKey: key, cost: cost(of: image))
        return image
    }

    /// Warms the previous and next page off the main thread so a swipe lands on
    /// bitmaps that are already decoded.
    func prefetchNeighbors(of page: Int, targetWidth: CGFloat) {
        let maxPixelSize = pixelSize(forTargetWidth: targetWidth)
        prefetch(page: page - 1, maxPixelSize: maxPixelSize)
        prefetch(page: page + 1, maxPixelSize: maxPixelSize)
    }

    /// Drops every cached bitmap. Called on a memory warning.
    func purge() {
        cache.removeAllObjects()
    }

    // MARK: - Decoding

    private func decode(page: Int, line: Int, maxPixelSize: Int) -> UIImage? {
        guard let path = imagePath(page: page, line: line) else { return nil }

        let sourceOptions: [CFString: Any] = [kCGImageSourceShouldCache: false]
        guard let source = CGImageSourceCreateWithURL(
            URL(fileURLWithPath: path) as CFURL,
            sourceOptions as CFDictionary
        ) else { return nil }

        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(
            source, 0, thumbnailOptions as CFDictionary
        ) else { return nil }

        return UIImage(cgImage: cgImage, scale: screenScale, orientation: .up)
    }

    /// Same two-path bundle lookup the view used before: the flat resource
    /// folder first, then the directory-scoped bundle lookup.
    private func imagePath(page: Int, line: Int) -> String? {
        if let resourcePath = Bundle.main.resourcePath {
            let candidate = "\(resourcePath)/\(page)/\(line).png"
            if FileManager.default.fileExists(atPath: candidate) { return candidate }
        }
        return Bundle.main.path(forResource: "\(line)", ofType: "png", inDirectory: "\(page)")
    }

    // MARK: - Prefetch

    private func prefetch(page: Int, maxPixelSize: Int) {
        guard page >= 1 else { return }

        for line in 1...Self.linesPerPage {
            let key = cacheKey(page: page, line: line, maxPixelSize: maxPixelSize)
            guard cache.object(forKey: key as NSString) == nil, claim(key) else { continue }

            prefetchQueue.async { [weak self] in
                guard let self else { return }
                defer { self.release(key) }

                guard self.cache.object(forKey: key as NSString) == nil,
                      let image = self.decode(page: page, line: line, maxPixelSize: maxPixelSize)
                else { return }

                self.cache.setObject(image, forKey: key as NSString, cost: self.cost(of: image))
            }
        }
    }

    /// Returns true when this call took ownership of decoding `key`.
    private func claim(_ key: String) -> Bool {
        inFlightLock.lock()
        defer { inFlightLock.unlock() }
        return inFlight.insert(key).inserted
    }

    private func release(_ key: String) {
        inFlightLock.lock()
        inFlight.remove(key)
        inFlightLock.unlock()
    }

    // MARK: - Helpers

    private func cacheKey(page: Int, line: Int, maxPixelSize: Int) -> String {
        "\(page)/\(line)@\(maxPixelSize)"
    }

    /// Longest-side pixel budget for the thumbnail, bucketed to 32px so minor
    /// geometry jitter does not fragment the cache.
    private func pixelSize(forTargetWidth targetWidth: CGFloat) -> Int {
        let pixels = max(targetWidth, 1) * screenScale
        return max(32, Int((pixels / 32).rounded(.up)) * 32)
    }

    private func cost(of image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 0 }
        return cgImage.bytesPerRow * cgImage.height
    }
}
