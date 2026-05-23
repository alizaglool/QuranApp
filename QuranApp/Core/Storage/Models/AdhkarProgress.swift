//
//  AdhkarProgress.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 2026-04-02.
//


import Foundation
import SwiftData

@Model
final class AdhkarProgress {
    var adhkarId: String
    var currentCount: Int
    var targetCount: Int
    var lastUpdated: Date
    
    init(
        adhkarId: String,
        currentCount: Int = 0,
        targetCount: Int = 33
    ) {
        self.adhkarId = adhkarId
        self.currentCount = currentCount
        self.targetCount = targetCount
        self.lastUpdated = Date()
    }
}