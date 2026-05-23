//
//  SplashViewModel.swift
//  EMLE Learners
//
//  Created by Ali M. Zaghloul on 03/04/2024.
//

import Foundation
import Core

final class SplashViewModel: MainViewModel {
    
    @Published var logoScale: CGFloat = 0
    @Published var logoOpacity: CGFloat = 0
    
    private var animationDurations: [CGFloat] = [0.0, 1.0, 1.75, 2.50]
    
    var coordinator: SplashCoordinating
    
    init(coordinator: SplashCoordinating) {
        self.coordinator = coordinator
    }
}

extension SplashViewModel {
    
    func onAppear() {
        startAnimationSequence()
        navigateAfterDelay()
    }
    
    private func navigateAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) { [weak self] in
            self?.coordinator.coordinateToMainScreen()
        }
    }
    
    private func startAnimationSequence() {
        logoScale = 0.6
        logoOpacity = 0.0
        
        withOptionalAnimation(.easeIn(duration: animationDurations[1] - animationDurations[0])
            .delay(animationDurations[0])) {
                logoScale = 1.1
                logoOpacity = 0.5
            }
        
        withOptionalAnimation(.easeInOut(duration: animationDurations[2] - animationDurations[1])
            .delay(animationDurations[1])) {
                logoScale = 0.9
                logoOpacity = 0.8
            }
        
        withOptionalAnimation(.easeOut(duration: animationDurations[3] - animationDurations[2])
            .delay(animationDurations[2])) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
    }
}
