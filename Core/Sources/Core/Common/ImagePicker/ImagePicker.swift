//
//  ImagePicker.swift
//  Core
//
//  Created by Ali M. Zaghloul on 05/05/2025.
//


import SwiftUI

public struct ImagePicker: View {
    
    @Binding var pickerImage: ImagePickerImage
    
    var sourceType: ImagePickerSourceType
    
    public init(pickerImage: Binding<ImagePickerImage>,
                sourceType: ImagePickerSourceType) {
        self._pickerImage = pickerImage
        self.sourceType = sourceType
    }
    
    public var body: some View {
        
        switch sourceType {
            
        case .photos:
            
            PhotosImagePicker(pickerImage: $pickerImage)
            
        case .camera:
            CameraImagePicker(pickerImage: $pickerImage)
        }
    }
}
