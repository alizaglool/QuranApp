//
//  AthkarFavoritesStore.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 26/10/2026.
//

import Foundation
import Combine
import Core

// MARK: - Reference

struct AthkarItemReference: Hashable, Codable, Identifiable {
    let packKey: String
    let itemID: Int

    var id: String { "\(packKey)#\(itemID)" }

    init(packKey: String, itemID: Int) {
        self.packKey = packKey
        self.itemID = itemID
    }

    init?(id: String) {
        let parts = id.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2, let itemID = Int(parts[1]), !parts[0].isEmpty else { return nil }
        self.packKey = String(parts[0])
        self.itemID = itemID
    }
}

// MARK: - Store

final class AthkarFavoritesStore: ObservableObject {

    static let shared = AthkarFavoritesStore()

    private static let storageKey = "athkar_favorites"

    @Published private(set) var references: [AthkarItemReference] = []

    private let defaults: UserDefaults
    private var identifiers: Set<String> = []

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        restore()
    }

    // MARK: - Queries

    var count: Int { references.count }

    var isEmpty: Bool { references.isEmpty }

    func isFavorite(itemID: Int, inPack packKey: String) -> Bool {
        identifiers.contains(AthkarItemReference(packKey: packKey, itemID: itemID).id)
    }

    func references(inPack packKey: String) -> [AthkarItemReference] {
        references.filter { $0.packKey == packKey }
    }

    // MARK: - Mutation

    func toggle(itemID: Int, inPack packKey: String) {
        let reference = AthkarItemReference(packKey: packKey, itemID: itemID)
        if identifiers.contains(reference.id) {
            identifiers.remove(reference.id)
            references.removeAll { $0 == reference }
        } else {
            identifiers.insert(reference.id)
            references.insert(reference, at: 0)
        }
        persist()
    }

    func remove(itemID: Int, inPack packKey: String) {
        let reference = AthkarItemReference(packKey: packKey, itemID: itemID)
        guard identifiers.remove(reference.id) != nil else { return }
        references.removeAll { $0 == reference }
        persist()
    }

    func removeAll() {
        guard !references.isEmpty else { return }
        identifiers.removeAll()
        references.removeAll()
        persist()
    }

    // MARK: - Storage

    private func restore() {
        let stored = defaults.array(forKey: Self.storageKey) as? [String] ?? []
        references = stored.compactMap(AthkarItemReference.init(id:))
        identifiers = Set(references.map(\.id))
    }

    private func persist() {
        defaults.set(references.map(\.id), forKey: Self.storageKey)
    }
}
