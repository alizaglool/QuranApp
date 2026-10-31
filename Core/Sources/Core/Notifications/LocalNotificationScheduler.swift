//
//  LocalNotificationScheduler.swift
//  Core
//
//  Created by Ali Zaghloul on 30/10/2026.
//

import Foundation

public enum LocalNotificationPendingBudget {

    public static let requestLimit = 64

    public static func affordableGroups<Element>(
        _ groups: [[Element]],
        limit: Int = LocalNotificationPendingBudget.requestLimit
    ) -> [[Element]] {
        var affordable: [[Element]] = []
        var total = 0

        for group in groups where !group.isEmpty {
            guard total + group.count <= limit else { break }
            affordable.append(group)
            total += group.count
        }

        return affordable
    }
}

@MainActor
public final class LocalNotificationScheduler {

    public let ownedIdentifierPrefix: String

    private let center: LocalNotificationCenter

    public init(center: LocalNotificationCenter, ownedIdentifierPrefix: String) {
        self.center = center
        self.ownedIdentifierPrefix = ownedIdentifierPrefix
    }

    public func isOwned(_ identifier: String) -> Bool {
        identifier.hasPrefix(ownedIdentifierPrefix)
    }

    public func currentAuthorizationStatus() async -> LocalNotificationAuthorizationStatus {
        await center.currentAuthorizationStatus()
    }

    public func requestAuthorization() async -> LocalNotificationAuthorizationStatus {
        await center.requestAuthorization()
    }

    public func pendingOwnedIdentifiers() async -> [String] {
        await center.pendingRequestIdentifiers().filter(isOwned)
    }

    public func removeOwnedRequests() async {
        let owned = await pendingOwnedIdentifiers()
        guard !owned.isEmpty else { return }
        center.removeRequests(withIdentifiers: owned)
    }

    public func replaceOwnedRequests(with drafts: [LocalNotificationRequestDraft]) async {
        await removeOwnedRequests()

        for draft in drafts {
            await center.add(draft)
        }
    }
}
