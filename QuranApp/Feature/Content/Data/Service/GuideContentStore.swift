//
//  GuideContentStore.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import Foundation

final class GuideContentStore {

    static let shared = GuideContentStore()

    static let bundledDirectory = "Athkar/Packs"

    private let bundle: Bundle
    private let lock = NSLock()
    private var cache: [String: GuideContent] = [:]

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    // MARK: - Reading

    func content(for key: GuideKey) -> GuideContent? {
        content(forKey: key.rawValue)
    }

    func content(forKey key: String) -> GuideContent? {
        lock.lock()
        if let hit = cache[key] {
            lock.unlock()
            return hit
        }
        lock.unlock()

        guard let loaded = try? decode(key: key) else { return nil }

        lock.lock()
        cache[key] = loaded
        lock.unlock()

        return loaded
    }

    func isAvailable(_ key: GuideKey) -> Bool {
        guard let content = content(for: key) else { return false }
        return !content.items.isEmpty
    }

    func purge() {
        lock.lock()
        cache.removeAll()
        lock.unlock()
    }

    // MARK: - Decoding

    private func decode(key: String) throws -> GuideContent {
        guard let url = resourceURL(key: key) else { throw GuideContentError.missingResource }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(GuideContent.self, from: data)
    }

    private func resourceURL(key: String) -> URL? {
        let name = "zikr_athkar_\(key)"
        return bundle.url(forResource: name, withExtension: "json", subdirectory: Self.bundledDirectory)
            ?? bundle.url(forResource: name, withExtension: "json")
    }
}

// MARK: - GuideContentError

enum GuideContentError: Error {
    case missingResource
}
