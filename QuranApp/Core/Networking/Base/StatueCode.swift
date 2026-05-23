//
//  StatueCode.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 24/04/2025.
//

import Foundation
import UIKit

// MARK: - Status Code
 
typealias StatusCode = Int

extension StatusCode {
    static let success: StatusCode = 200
    
    static let unauthenticated: StatusCode = 401
    static let unauthorized: StatusCode = 403
    static let notFound: StatusCode = 404
    
    static let secretKeyMissingOrExpired: StatusCode = 410
    static let validationError: StatusCode = 422
    static let serverError: StatusCode = 500
    static let serviceUnavailable: StatusCode = 503
    
    var isSuccess: Bool { self == .success }
    
    var isUnauthenticated: Bool { self == .unauthenticated }
    var isUnauthorized: Bool { self == .unauthorized }
    var isNotFound: Bool { self == .notFound }
    
    var isSecretKeyMissingOrExpired: Bool { self == .secretKeyMissingOrExpired }
    var isValidationError: Bool { self == .validationError }
    var isServerError: Bool { self == .serverError }
    var isServiceUnavailable: Bool { self == .serviceUnavailable }
}
