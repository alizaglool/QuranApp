//
//  CustomImageView.swift
//  Core
//
//  Created by Ali M. Zaghloul on 05/05/2025.
//


import SwiftUI

public struct CustomImageView: View {
    
    var image: ImageUrl?
    
    var placeholder: Image
    
    var contentMode: ContentMode
    
    public init(image: ImageUrl?,
                placeholder: Image = Image("profileIcon"),
                contentMode: ContentMode  = .fill) {
        self.image = image
        self.placeholder = placeholder
        self.contentMode = contentMode
    }
    
    public var body: some View {
        Rectangle()
            .opacity(0.0)
            .overlay {
                
                imageView
                    .allowsHitTesting(false)
            }
            .clipped()
    }
    
    @ViewBuilder
    private var imageView: some View {
        if image != nil {
            
//            KFAsyncImage(url: image.url,
//                         contentMode: contentMode)
        }
        else {
            
            placeholder
                .resizable()
                .aspectRatio(contentMode: contentMode)
        }
    }
}

#Preview {
    CustomImageView(image: nil)
}
