//
//  Header.swift
//  
//
//  Created by Zaghloul on 10/04/2025.
//

import Alamofire

struct Header {
    static let shared = Header()
    private init() {}
    
    func createHeader() -> HTTPHeaders {
        var headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        
//        if let token = LocalStorage.shared.getUserModel()?.token, !token.isEmpty {
//            headers.add(name: "Authorization", value: "Bearer \(token)")
//        }
        
        return headers
    }
}
