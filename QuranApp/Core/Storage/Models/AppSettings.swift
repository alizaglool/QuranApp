//
//  AppSettings.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 2026-04-02.
//


import Foundation
import SwiftData

@Model
final class AppSettings {
    var selectedLanguage: String
    var selectedReciterId: String
    var selectedReciterName: String
    var fontSize: Double
    var themeMode: String
    var isOnboardingCompleted: Bool
    var createdAt: Date
    
    init(
        selectedLanguage: String = "ar",
        selectedReciterId: String = "afasy",
        selectedReciterName: String = "مشاري العفاسي",
        fontSize: Double = 1.0,
        themeMode: String = "system",
        isOnboardingCompleted: Bool = false
    ) {
        self.selectedLanguage = selectedLanguage
        self.selectedReciterId = selectedReciterId
        self.selectedReciterName = selectedReciterName
        self.fontSize = fontSize
        self.themeMode = themeMode
        self.isOnboardingCompleted = isOnboardingCompleted
        self.createdAt = Date()
    }
}