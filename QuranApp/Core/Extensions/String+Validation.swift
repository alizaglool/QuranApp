//
//  String+Validation.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 26/04/2025.
//


import Foundation

let firstPart = "[A-Z0-9a-z]([A-Z0-9a-z._%+-]{0,30}[A-Z0-9a-z])?"
let serverPart = "([A-Z0-9a-z]([A-Z0-9a-z-]{0,30}[A-Z0-9a-z])?\\.){1,5}"
let emailRegex = firstPart + "@" + serverPart + "[A-Za-z]{2,8}"
let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)

private let passwordRegex = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[@$!%*?&])[A-Za-z\\d@$!%*?&]{8,}$"
private let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)

private let nameRegex = "^[A-Za-z\u{0600}-\u{06FF}]{2,}$"
private let namePredicate = NSPredicate(format: "SELF MATCHES %@", nameRegex)

private let fullNameRegex = "^[\\u0600-\\u06FFA-Za-z ]{2,}$"
private let fullNamePredicate = NSPredicate(format: "SELF MATCHES %@", fullNameRegex)

private let phoneRegex = "^[0-9]{10,15}$"
private let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)

/// Item name must be at least 2 characters and contain only letters, numbers, or spaces
private let itemNameRegex = "^[A-Za-z0-9 ]{2,}$"
private let itemNamePredicate = NSPredicate(format: "SELF MATCHES %@", itemNameRegex)

/// Description must be at least 5 characters.
private let itemDescriptionRegex = "^.{5,}$"
private let itemDescriptionPredicate = NSPredicate(format: "SELF MATCHES %@", itemDescriptionRegex)

/// Unit must contain only letters and spaces
private let itemUnitRegex = "^[A-Za-z ]{1,}$"
private let itemUnitPredicate = NSPredicate(format: "SELF MATCHES %@", itemUnitRegex)

/// Barcode must be 8 to 14 digits
private let itemBarcodeRegex = "^\\d{8,14}$"
private let itemBarcodePredicate = NSPredicate(format: "SELF MATCHES %@", itemBarcodeRegex)

/// Tag must be 1 to 20 characters long, with letters and numbers only
private let itemTagRegex = "^[A-Za-z0-9]{1,20}$"
private let itemTagPredicate = NSPredicate(format: "SELF MATCHES %@", itemTagRegex)


extension String {
    
    func isValidEmail() -> Bool {
        print(self)
        print(emailPredicate.evaluate(with: self))
        return emailPredicate.evaluate(with: self)
    }
    
    func isValidPassword() -> Bool {
        print(self)
        print(passwordPredicate.evaluate(with: self))
        return passwordPredicate.evaluate(with: self)
    }
    
    func isValidName() -> Bool {
        print(self)
        print(namePredicate.evaluate(with: self.trimmingCharacters(in: .whitespacesAndNewlines)))
        return namePredicate.evaluate(with: self.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    func isValidFullName() -> Bool {
        return fullNamePredicate.evaluate(with: self.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    func isValidPhone() -> Bool {
        return phonePredicate.evaluate(with: self.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    func isValidItemName() -> Bool {
        return itemNamePredicate.evaluate(with: self.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    func isValidItemDescription() -> Bool {
        return itemDescriptionPredicate.evaluate(with: self.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    func isValidItemUnit() -> Bool {
        return itemUnitPredicate.evaluate(with: self.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    func isValidItemBarcode() -> Bool {
        return itemBarcodePredicate.evaluate(with: self.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    func isValidItemTag() -> Bool {
        return itemTagPredicate.evaluate(with: self.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
