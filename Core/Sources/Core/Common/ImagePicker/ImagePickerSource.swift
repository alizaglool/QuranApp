//
//  ImagePickerSource.swift
//  Core
//
//  Created by Ali M. Zaghloul on 18/06/2025.
//


import SwiftUI

public struct ImagePickerSource: View {
    
    var uploadPhotoAction: EmptyAction
    var takePhotoAction: EmptyAction
    
    public init(uploadPhotoAction: EmptyAction = nil,
                takePhotoAction: EmptyAction = nil) {
        self.uploadPhotoAction = uploadPhotoAction
        self.takePhotoAction = takePhotoAction
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            uploadPhoto
            
            takePhoto
        }
        .padding(16)
        .customBackground(.container)
    }
    
    private var uploadPhoto: some View {
        PrimaryButton(title: "Upload Photo",
                      action: uploadPhotoAction)
    }
    
    private var takePhoto: some View {
        OutlinedButton(title: "Take Photo",
                       action: takePhotoAction)
    }
}

#Preview {
    ImagePickerSource()
}
