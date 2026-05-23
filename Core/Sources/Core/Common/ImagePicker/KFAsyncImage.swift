//
//  KFAsyncImage.swift
//  Core
//
//  Created by Ali M. Zaghloul on 05/05/2025.
//


//import SwiftUI
//import Kingfisher
//
//struct KFAsyncImage: View {
//    
//    var url: URL?
//    var contentMode: SwiftUI.ContentMode = .fill
//    
//    @State private var errorOccured: Bool = false
//    
//    var body: some View {
//        if errorOccured {
//            errorImage
//        }
//        else {
//            KFImage(url)
//                .placeholder({ placeholderImage })
//                .onFailure({ error in
//                    errorOccured = true
//                })
//                .resizable()
//                .aspectRatio(contentMode: contentMode)
//        }
//    }
//    
//    private var placeholderImage: some View {
//        Color.gray.opacity(0.1)
//            .overlay {
//                
//                ProgressView()
//            }
//    }
//    
//    private var errorImage: some View {
//        Color.gray.opacity(0.1)
//            .overlay {
//                
//                Image.questionMark
//                    .customForeground(.onSurface)
//            }
//    }
//}
//
//#Preview {
//    KFAsyncImage()
//}
