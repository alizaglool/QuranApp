//
//  ListView.swift
//  Core
//
//  Created by Ali M. Zaghloul on 26/06/2025.
//


import SwiftUI

public struct ListView<T, Content: View>: View {
    
    var dataArray: [T]
    var noDataMessage: String
    var noDataSubMessage: String
    var noDataImage: Image?
    
    var noItemsButtonTitle: String
    var noDataAction: EmptyAction
    
    @ViewBuilder var content: () -> Content
    
    public init(dataArray: [T] = [],
                noDataMessage: String = "BasicStrings.empty.localized",
                noDataImage: Image? = .noData,
                noDataSubMessage: String = "",
                noItemsButtonTitle: String = "",
                noDataAction: EmptyAction = nil,
                @ViewBuilder content: @escaping () -> Content) {
        self.dataArray = dataArray
        self.noDataImage = noDataImage
        self.noDataMessage = noDataMessage
        self.noDataSubMessage = noDataSubMessage
        self.noItemsButtonTitle = noItemsButtonTitle
        self.noDataAction = noDataAction
        self.content = content
    }
    
    public var body: some View {
        if dataArray.isEmpty {
            VStack(spacing: 32) {
                                
                VStack(spacing: 16) {
                    
                    Spacer(minLength: 50)
                    
                    if let noDataImage {
                        noDataImage
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(.horizontal, 64)
                    }
                    
                    Text(noDataMessage)
                        .customStyle(.heading2, .onSurface)
                        .multilineTextAlignment(.center)
                    
                    if !noDataSubMessage.isEmpty {
                        
                        Text(noDataSubMessage)
                            .customStyle(.heading3, .onSurface)
                            .multilineTextAlignment(.center)
                    }
                    
                    if let noDataAction {
                        
                        PrimaryButton(title: noItemsButtonTitle,
                                      action: noDataAction)
                    }
                }
                .padding(.horizontal, 32)
            }
            .frame(maxWidth: .infinity)
        }
        else {
            content()
        }
    }
}

#Preview {
    ListView(dataArray: []) {
        
        VStack {
            
        }
    }
}
