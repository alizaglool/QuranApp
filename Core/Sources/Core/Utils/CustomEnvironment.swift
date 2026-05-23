//
//  CustomEnvironment.swift
//
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import Foundation

public enum CustomEnvironment {
    
    static let baseURL: String = getValue(for: .baseUrl)
    static let appSecret: String = getValue(for: .appSecret)
    
    private enum PlistKeys: String {
        case baseUrl = "BASE_URL"
        case appSecret = "APP_SECRET"
    }
    
    private static func getValue(for key: PlistKeys) -> String {
        
        guard let value = CustomEnvironment.infoDictionary[key.rawValue] as? String else {
            fatalError("\(key.rawValue) doesn't exist in plist") }
        
        return value
    }
    
    private static let infoDictionary: [String: Any] = {
        guard let dictionary = Bundle.main.infoDictionary else { fatalError("Plist file is not found") }
        return dictionary
    }()
}
