//
//  MyAdhkarViewModel.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 26/09/2026
//

import Foundation
import Combine

@MainActor
final class MyAdhkarViewModel: ObservableObject {

    @Published private(set) var myAdhkar: [MyDhikr] = []
    @Published private(set) var sessionCounts: [String: Int] = [:]

    private let storageKey = "my_adhkar_v2"

    init() { load() }

    func add(_ text: String, count: Int = 33) {
        let dhikr = MyDhikr(textAr: text, count: count)
        myAdhkar.insert(dhikr, at: 0)
        save()
    }

    func delete(_ dhikr: MyDhikr) {
        myAdhkar.removeAll { $0.id == dhikr.id }
        sessionCounts.removeValue(forKey: dhikr.id)
        save()
    }

    @discardableResult
    func incrementCount(for dhikr: MyDhikr) -> Int {
        let current = sessionCounts[dhikr.id] ?? 0
        let next = min(current + 1, dhikr.count)
        sessionCounts[dhikr.id] = next
        return next
    }

    func resetCount(for dhikr: MyDhikr) {
        sessionCounts[dhikr.id] = 0
    }

    func resetSession() {
        sessionCounts = [:]
    }

    private func save() {
        if let data = try? JSONEncoder().encode(myAdhkar) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([MyDhikr].self, from: data) else {
            migrateLegacyData()
            return
        }
        myAdhkar = decoded
    }

    private func migrateLegacyData() {
        guard let data = UserDefaults.standard.data(forKey: "my_adhkar_v1"),
              let legacy = try? JSONDecoder().decode([LegacyMyDhikr].self, from: data) else { return }
        myAdhkar = legacy.map { MyDhikr(id: $0.id, textAr: $0.textAr, count: 33, createdAt: $0.createdAt) }
        save()
    }
}

private struct LegacyMyDhikr: Codable {
    let id: String
    let textAr: String
    let createdAt: Date
}
