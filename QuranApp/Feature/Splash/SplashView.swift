//
//  SplashView.swift
//  EMLE Learners
//
//  Created by Ali M. Zaghloul on 03/04/2024.
//

import Core
import SwiftUI

struct SplashView: View {
    @StateObject var viewModel: SplashViewModel
    
    init(coordinator: SplashCoordinating) {
        _viewModel = StateObject(wrappedValue: SplashViewModel(coordinator: coordinator))
    }
    
    var body: some View {
        MainView(viewModel: viewModel) {
            ZStack {
                Color.background
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    Image.splashLogo
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                    
                    VStack(spacing: 4) {
                        Text(AppLocalizedKeys.appName.value)
                            .customStyle(.heading1, .primary)
                        
                        Text(AppLocalizedKeys.appNameEnglish.value)
                            .customStyle(.caption1, .subtitle)
                    }
                }
                .opacity(viewModel.logoOpacity)
                .scaleEffect(viewModel.logoScale)
            }
        }
    }
}
