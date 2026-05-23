//
//  SplashCoordinator.swift
//  EMLE Learners
//
//  Created by Ali M. Zaghloul on 03/04/2024.
//

import UIKit
import Core

protocol SplashCoordinating: AnyObject {
    func coordinateToSelectLanguage()
    func coordinateToMainScreen()
}

class SplashCoordinator: MainCoordinator, SplashCoordinating {
    
    var navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        let splashView = SplashView(coordinator: self)
        coordinateToView(splashView)
    }
    
    func coordinateToMainScreen() {
        let tabBarCoordinator = TabBarCoordinator(navigationController: navigationController)
        coordinate(to: tabBarCoordinator)
    }
    
    func coordinateToSelectLanguage() {
//        let onbordingCoordinator = SelectLanguageCoordinator(navigationController: navigationController)
//        coordinate(to: onbordingCoordinator)
    }
}
