//
//  DomainWrapper.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 24/04/2025.
//


// MARK: - Domain Wrapper

typealias DomainBool = DomainWrapper<Bool>
typealias DomainString = DomainWrapper<String>
typealias DomainEmpty = DomainWrapper<EmptyResponse>

struct DomainWrapper<T: Decodable> {
    public var statusCode: Int
    public var statusDescription: String?
    public var message: String
    public var data: T?
    public var isSuccess: Bool
    public var isFail: Bool
    
    // Computed properties
    public var success: Bool { isSuccess }
    
    // Initialize from APIResponse
    public init(from apiResponse: APIResponse<T>) {
        self.statusCode = apiResponse.status ?? 500
        self.statusDescription = apiResponse.statusDescription
        self.message = apiResponse.message
        self.data = apiResponse.data
        self.isSuccess = apiResponse.success
        self.isFail = apiResponse.failure
    }
    
    // Direct initializer
    public init(statusCode: Int, statusDescription: String? = nil, message: String, data: T? = nil, isSuccess: Bool = false, isFail: Bool = false) {
        self.statusCode = statusCode
        self.statusDescription = statusDescription
        self.message = message
        self.data = data
        self.isSuccess = isSuccess
        self.isFail = isFail
    }
    
    public static func success(data: T?, message: String = "Success", statusDescription: String? = nil) -> DomainWrapper<T> {
        return DomainWrapper(statusCode: 200, statusDescription: statusDescription, message: message, data: data, isSuccess: true, isFail: false)
    }
    
    public static func failure(statusCode: Int = 500, statusDescription: String? = nil, message: String) -> DomainWrapper<T> {
        return DomainWrapper(statusCode: statusCode, statusDescription: statusDescription, message: message, isSuccess: false, isFail: true)
    }
}

struct EmptyResponse: Decodable {}
