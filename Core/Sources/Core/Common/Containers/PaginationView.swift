//
//  PaginationView.swift
//
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import SwiftUI

public struct PaginationView<Content: View>: View {
    
    var direction: Axis
    var canGetANewPage: Bool
    var getNewPageAction: EmptyAction
    
    @ViewBuilder var content: () -> Content
    
    public init(direction: Axis = .horizontal,
                canGetANewPage: Bool,
                getNewPageAction: EmptyAction,
                @ViewBuilder content: @escaping () -> Content) {
        self.direction = direction
        self.canGetANewPage = canGetANewPage
        self.getNewPageAction = getNewPageAction
        self.content = content
    }
    
    public var body: some View {
        switch direction {
            
        case .horizontal:
            horizontalBody
            
        case .vertical:
            verticalBody
        }
    }
    
    private var horizontalBody: some View {
        HStack(spacing: 16) {
            
            content()
            
            if canGetANewPage {
                
                LazyHStack {
                    
                    ProgressView()
                        .onAppear {
                            getNewPageAction?()
                        }
                }
            }
        }
    }
    
    private var verticalBody: some View {
        VStack(spacing: 16) {
            
            content()
            
            if canGetANewPage {
                
                LazyVStack {
                    
                    ProgressView()
                        .onAppear {
                            getNewPageAction?()
                        }
                }
            }
        }
    }
}

#Preview {
    PaginationViewTest1()
}

#Preview {
    PaginationViewTest2()
}

struct PaginationViewTest1: View {
    
    @State var items: [String] = []
    
    var body: some View {
        NoIndicatorsScrollView(.vertical) {
            
            PaginationView(direction: .vertical,
                           canGetANewPage: true,
                           getNewPageAction: getNewPageAction) {
                list
            }
                           .customContentPadding(.vertical, 20)
        }
        .customContentMargins(.vertical, 20)
    }
    
    private var list: some View {
        VStack(spacing: 20) {
            ForEach(items, id: \.self) { item in
                Text(item)
            }
        }
    }
    
    private func getNewPageAction() {
        
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 2) {
            for i in items.count...items.count+20 {
                items.append("Option \(i)")
            }
        }
    }
}

struct PaginationViewTest2: View {
    
    @State var items: [String] = []
    
    var body: some View {
        NoIndicatorsScrollView(.horizontal) {
            
            PaginationView(direction: .horizontal,
                           canGetANewPage: true,
                           getNewPageAction: getNewPageAction) {
                list
            }
                           .customContentPadding(.horizontal, 20)
        }
        .customContentMargins(.horizontal, 20)
    }
    
    private var list: some View {
        HStack(spacing: 20) {
            ForEach(items, id: \.self) { item in
                Text(item)
            }
        }
    }
    
    private func getNewPageAction() {
        
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 2) {
            for i in items.count...items.count+10 {
                items.append("Option \(i)")
            }
        }
    }
}
