//
//  MainView.swift
//
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import SwiftUI

public struct MainView<ViewModel: MainViewModel, Content: View>: View {
    
    var viewModel: ViewModel
    
    @ViewBuilder var content: () -> Content
    
    public init(viewModel: ViewModel,
                @ViewBuilder content: @escaping () -> Content) {
        self.viewModel = viewModel
        self.content = content
    }
    
    public var body: some View {
        Group {
            if #available(iOS 16.0, *) {
                iOS16Body
            }
            else {
                iOS15Body
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .customBackground(.surface)
        .onAppear {
            viewModel.isTabBarVisible ? showTabBar() : hideTabBar()
            viewModel.onAppear()
        }
        .onDisappear {
            if !viewModel.isTabBarVisible { showTabBar() }
            viewModel.onDisappear()
        }
    }
    
    private var iOS15Body: some View {
        VStack(spacing: 0) {
            
            content()
        }
        .navigationBarHidden(true)
    }
    
    @available(iOS 16.0, *)
    private var iOS16Body: some View {
        VStack(spacing: 0) {
            
            content()
        }
        .toolbar(.hidden)
    }
}
