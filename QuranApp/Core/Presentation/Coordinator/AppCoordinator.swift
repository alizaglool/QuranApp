//
//  AppCoordinator.swift
//  EMLE Learners
//
//  Created by Ali M. Zaghloul on 03/04/2024.
//

import UIKit
import Core

class AppCoordinator: AppCoordinatorProtocol {
    
    var window: UIWindow
    
    var navigationController: UINavigationController
    
    required init(window: UIWindow) {
        self.window = window
        navigationController = UINavigationController()
    }
    
    func start() { }
    
    func start(showSplash: Bool) {
        
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        
        if showSplash {
            let splashCoordinator = SplashCoordinator(navigationController: navigationController)
            coordinate(to: splashCoordinator)
        }
        else {
//            let signInCoordinator = LoginCoordinator(navigationController: navigationController)
//            coordinate(to: signInCoordinator)
        }
    }
}
