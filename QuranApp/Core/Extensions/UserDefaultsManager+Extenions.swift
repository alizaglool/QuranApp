//
//  UserDefaultsManager+Extenions.swift
//  EMLE Teams
//
//  Created by Ali M. Zaghloul on 27/10/2024.
//

import Foundation
import Core

enum UserDefaultsKeys: String {
    case phoneNumber = "com.emle.phoneNumber.user"
}

struct UserDefaultsManage {
    
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Phone Number Management
    
    func setPhoneNumber(_ phoneNumber: String) {
        userDefaults.set(phoneNumber, forKey: UserDefaultsKeys.phoneNumber.rawValue)
    }
    
    func getPhoneNumber() -> String? {
        return userDefaults.string(forKey: UserDefaultsKeys.phoneNumber.rawValue)
    }
    
    func removePhoneNumber() {
        userDefaults.removeObject(forKey: UserDefaultsKeys.phoneNumber.rawValue)
    }
}
