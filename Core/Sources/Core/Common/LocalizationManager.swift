//
//  LocalizationManagerSwiftUI.swift
//  Core
//
//  Created by Ali M. Zaghloul on 05/07/2025.
//


import SwiftUI

public protocol LocalizationDelegate: AnyObject {
    func resetAppAfterChangeLanguge()
    func resetAppFromTabBar()
}

public final class LocalizationManager: ObservableObject {
    
    public enum Language: String, CaseIterable {
        case English = "en"
        case Arabic = "ar"
        
        public var code: String { rawValue }
        
        public var direction: LayoutDirection {
            switch self {
            case .English: return .leftToRight
            case .Arabic: return .rightToLeft
            }
        }
    }
    
    public static let shared = LocalizationManager()
    
    @Published public var currentLanguage: Language {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: languageKey)
            UserDefaults.standard.synchronize()
            updateBundle()
        }
    }
    
    public weak var delegate: LocalizationDelegate?
    
    public private(set) var bundle: Bundle = .main
    private let languageKey = "UKPrefLang"
    
    private init() {
        if let code = UserDefaults.standard.string(forKey: languageKey),
           let lang = Language(rawValue: code) {
            self.currentLanguage = lang
        } else {
            self.currentLanguage = .English
        }
        updateBundle()
    }
    
    // MARK: - Public
    
    public func localized(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }
    
    public func setLanguage(_ language: Language, fromTabBar: Bool = false) {
        currentLanguage = language
        resetApp(fromTabBar)
    }
    
    public func setAppInnitLanguage() {
        if let selectedLanguage = getSavedLanguage() {
            setLanguage(selectedLanguage)
        } else if let systemLang = Locale.preferredLanguages.first,
                  let availableLang = matchLanguage(systemLang) {
            setLanguage(availableLang)
        } else {
            setLanguage(.English)
        }
        resetApp(false)
    }
    
    // MARK: - Helpers
    
    private func updateBundle() {
        if let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            self.bundle = bundle
        } else {
            self.bundle = .main
        }
    }
    
    private func getSavedLanguage() -> Language? {
        guard let code = UserDefaults.standard.string(forKey: languageKey) else { return nil }
        return Language(rawValue: code)
    }
    
    private func matchLanguage(_ code: String) -> Language? {
        if code.contains("ar") { return .Arabic }
        if code.contains("en") { return .English }
        return nil
    }
    
    private func resetApp(_ fromTabBar: Bool) {
        applySemanticDirection()
        
        if fromTabBar {
            delegate?.resetAppFromTabBar()
        } else {
            delegate?.resetAppAfterChangeLanguge()
        }
    }
    
    private func applySemanticDirection() {
        let semantic: UISemanticContentAttribute = currentLanguage == .Arabic ? .forceRightToLeft : .forceLeftToRight
        
        // UIKit views
        UIView.appearance().semanticContentAttribute = semantic
        UITextField.appearance().semanticContentAttribute = semantic
        UITextView.appearance().semanticContentAttribute = semantic
        UINavigationBar.appearance().semanticContentAttribute = semantic
        UITabBar.appearance().semanticContentAttribute = semantic
        
        // Alignments
        UITextField.appearance().textAlignment = currentLanguage == .Arabic ? .right : .left
        UITextView.appearance().textAlignment = currentLanguage == .Arabic ? .right : .left
    }
}

extension String {
    public var localized: String {
        LocalizationManager.shared.localized(self)
    }
}
