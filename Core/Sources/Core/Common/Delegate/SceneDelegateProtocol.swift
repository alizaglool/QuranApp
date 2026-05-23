//
//  SceneDelegateProtocol.swift
//
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import UIKit

public protocol SceneDelegateProtocol: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow? { get set }
    
    var coordinator: AppCoordinatorProtocol? { get set }
    
    var coordinatorProvider: AppCoordinatorProtocol? { get  }
    
    func prepareApp()
}

public extension SceneDelegateProtocol {
    
    func prepareApp() {
        
        guard window != nil else { return }
        
        coordinator = coordinatorProvider
        
        var _: AppCoordinatorProtocol? = coordinator
        
        coordinator?.start(showSplash: true)
    }
}
