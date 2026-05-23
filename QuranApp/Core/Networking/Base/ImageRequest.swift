//
//  ImageRequest.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 24/04/2025.
//

import Foundation
import SwiftUI


// MARK: - Image Request

public struct ImageRequest {
    public var imageData: Data?
    public var imageName: String
    
    public init(imageData: Data? = nil, imageName: String) {
        self.imageData = imageData
        self.imageName = imageName
    }
}
