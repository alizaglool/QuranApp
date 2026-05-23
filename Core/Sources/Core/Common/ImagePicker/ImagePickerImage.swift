//
//  ImagePickerImage.swift
//  Core
//
//  Created by Ali M. Zaghloul on 05/05/2025.
//

import UIKit

public struct ImagePickerImage: Equatable {
    public var image: UIImage
    public var imageData: Data
}

public extension ImagePickerImage {
    
    static var empty: ImagePickerImage = {
        ImagePickerImage(image: .placeholder,
                         imageData: UIImage.placeholder.jpegData(compressionQuality: 1)!)
    }()
    
    static func == (lhs: ImagePickerImage, rhs: ImagePickerImage) -> Bool {
        return lhs.imageData == rhs.imageData
    }
}
