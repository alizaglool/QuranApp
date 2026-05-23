//
//  APIResponse.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 24/04/2025.
//

import Foundation

// MARK: - API Response Models

struct APIResponse<T: Decodable>: Decodable {
    let status: Int?
    let statusDescription: String?
    let data: T?
    let message: String
    let isSuccess: Bool
    let isFail: Bool?
    
    private enum CodingKeys: String, CodingKey {
        case status = "Status"
        case statusDescription = "StatusDescription"
        case data = "Data"
        case message = "Message"
        case isSuccess = "IsSuccess"
        case isFail = "IsFail"
    }
    
    var success: Bool {
        return isSuccess
    }
    
    var failure: Bool {
        return isFail ?? false
    }
}
