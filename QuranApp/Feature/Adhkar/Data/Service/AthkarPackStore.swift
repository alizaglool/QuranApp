//
//  AthkarPackStore.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 26/10/2026.
//

import Foundation
import Core

// MARK: - Store

final class AthkarPackStore {

    static let shared = AthkarPackStore()

    static let bundledDirectory = "Athkar/Packs"

    private let bundle: Bundle
    private let lock = NSLock()
    private var cache: [String: AthkarPackPayload] = [:]

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    // MARK: - Reading

    func payload(for pack: AthkarPack) -> AthkarPackPayload {
        payload(forKey: pack.key)
    }

    func payload(forKey key: String) -> AthkarPackPayload {
        lock.lock()
        if let hit = cache[key] {
            lock.unlock()
            return hit
        }
        lock.unlock()

        let loaded = (try? decode(key: key)) ?? .empty

        lock.lock()
        cache[key] = loaded
        lock.unlock()

        return loaded
    }

    func items(forKey key: String) -> [AthkarItem] {
        payload(forKey: key).items
    }

    func item(id: Int, inPack key: String) -> AthkarItem? {
        payload(forKey: key).item(id: id)
    }

    func isAvailable(_ pack: AthkarPack) -> Bool {
        resourceURL(key: pack.key) != nil
    }

    // MARK: - Search

    func search(_ query: String, in packs: [AthkarPack], limit: Int = 60) -> [AthkarSearchHit] {
        let needle = query.athkarSearchNormalized
        guard needle.count >= 2 else { return [] }

        var hits: [AthkarSearchHit] = []

        for pack in packs {
            for item in items(forKey: pack.key) {
                guard hits.count < limit else { return hits }
                guard let field = item.matchField(needle) else { continue }
                hits.append(AthkarSearchHit(packKey: pack.key,
                                            packName: pack.name,
                                            itemID: item.id,
                                            field: field,
                                            snippet: item.snippet(for: field)))
            }
        }

        return hits
    }

    // MARK: - Cache

    func purge() {
        lock.lock(); defer { lock.unlock() }
        cache.removeAll()
    }

    // MARK: - Loading

    private func decode(key: String) throws -> AthkarPackPayload {
        guard let url = resourceURL(key: key) else {
            throw AthkarDataError.missingResource(key)
        }
        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        let payload = try JSONDecoder().decode(AthkarPackPayload.self, from: data)
        guard payload.schemaVersion <= AthkarManifestService.supportedSchemaVersion else {
            throw AthkarDataError.unsupportedSchema(payload.schemaVersion)
        }
        return payload
    }

    private func resourceURL(key: String) -> URL? {
        let name = "zikr_athkar_\(key)"
        return bundle.url(forResource: name, withExtension: "json", subdirectory: Self.bundledDirectory)
            ?? bundle.url(forResource: name, withExtension: "json")
    }
}

// MARK: - Search hit

struct AthkarSearchHit: Identifiable, Hashable {
    let packKey: String
    let packName: String
    let itemID: Int
    let field: AthkarSearchField
    let snippet: String

    var id: String { "\(packKey)-\(itemID)-\(field.rawValue)" }
}

// MARK: - Search field

enum AthkarSearchField: String, Hashable {
    case title
    case body
    case translation
    case transliteration
    case note
}

// MARK: - Matching

private extension AthkarItem {

    func matchField(_ needle: String) -> AthkarSearchField? {
        if displayTitle.athkarSearchNormalized.contains(needle) { return .title }
        if plainText.athkarSearchNormalized.contains(needle) { return .body }
        if textEn.athkarSearchNormalized.contains(needle) { return .translation }
        if transliteration.athkarSearchNormalized.contains(needle) { return .transliteration }
        if notes.contains(where: { $0.text.athkarSearchNormalized.contains(needle) }) { return .note }
        return nil
    }

    func snippet(for field: AthkarSearchField) -> String {
        switch field {
        case .title:           return displayTitle
        case .body:            return plainText
        case .translation:     return textEn
        case .transliteration: return transliteration
        case .note:            return notes.first?.text ?? ""
        }
    }
}

// MARK: - Normalisation

extension String {

    var athkarSearchNormalized: String {
        let folded = folding(options: [.diacriticInsensitive, .caseInsensitive, .widthInsensitive],
                             locale: Locale(identifier: "en_US_POSIX"))
        var result = ""
        result.reserveCapacity(folded.count)

        for scalar in folded.unicodeScalars {
            switch scalar.value {
            case 0x0622, 0x0623, 0x0625, 0x0627, 0x0671:
                result.append("ا")
            case 0x0649, 0x064A:
                result.append("ي")
            case 0x0629:
                result.append("ه")
            case 0x0640, 0x064B...0x0655, 0x0670, 0x06D6...0x06ED:
                continue
            default:
                let character = Character(scalar)
                if character.isLetter || character.isNumber || character == " " {
                    result.append(character)
                } else {
                    result.append(" ")
                }
            }
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
