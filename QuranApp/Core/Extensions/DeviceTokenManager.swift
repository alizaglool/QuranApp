//
//  DeviceTokenManager.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 28/04/2025.
//


import UIKit

final class DeviceTokenManager {
    
    static let shared = DeviceTokenManager()
    
    private init() {}
    
    func getDeviceToken() -> String {
        UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    }
}
