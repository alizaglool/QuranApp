//
//  AppCoordinatorProtocol.swift
//  
//
//  Created by Ali M. Zaghloul on 7/6/24.
//

import UIKit

public protocol AppCoordinatorProtocol: MainCoordinator {
    
    var window: UIWindow { get }
    
    init(window: UIWindow)
    
    func start(showSplash: Bool)
}
