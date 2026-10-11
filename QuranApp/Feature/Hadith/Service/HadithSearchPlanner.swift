//
//  HadithSearchPlanner.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 06/10/2026.
//

import Foundation

enum HadithSearchPlanner {

    static let resultLimit = 50
    static let perBookFloor = 10
    static let scanCap = 200
    static let expandedLimit = 200

    struct BookCount {
        let bookId: Int
        let matches: Int
    }

    static func allocate(counts: [BookCount], limit: Int = resultLimit) -> [Int: Int] {
        let matching = counts.filter { $0.matches > 0 }
        guard !matching.isEmpty, limit > 0 else { return [:] }

        var quotas: [Int: Int] = [:]
        var remaining = limit

        let floor = max(1, min(perBookFloor, limit / matching.count))
        for entry in matching {
            guard remaining > 0 else { break }
            let share = min(entry.matches, floor, remaining)
            quotas[entry.bookId] = share
            remaining -= share
        }

        while remaining > 0 {
            var granted = 0
            for entry in matching {
                guard remaining > 0 else { break }
                let current = quotas[entry.bookId] ?? 0
                guard current < entry.matches else { continue }
                quotas[entry.bookId] = current + 1
                remaining -= 1
                granted += 1
            }
            guard granted > 0 else { break }
        }
        return quotas
    }
}
