//
//  ImageUrl.swift
//  Core
//
//  Created by Ali M. Zaghloul on 05/05/2025.
//


import Foundation

public struct ImageUrl: Codable {
    
    var urlString: String
    
    public var url: URL? { URL(string: urlString) }
    
    public init(urlString: String) {
        
        self.urlString = urlString
    }
}

public extension ImageUrl {
    static let placeholder: ImageUrl = {
        ImageUrl(urlString: "https://picsum.photos/200")
    }()
}