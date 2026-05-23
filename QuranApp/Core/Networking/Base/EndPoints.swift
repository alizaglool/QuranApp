//
//  File.swift
//  
//
//  Created by Zaghloul on 10/04/2025.
//

import Foundation

public enum EndPoints: String {
    
    case baseURL = "http://test.boniantech.com/API_MiniMarket/api/"
    
    public var value: String {
        return self.rawValue
    }
}
