//
//  TabBarCoordinator.swift
//  EMLE Learners
//
//  Created by Ali M. Zaghloul on 03/04/2024.
//

import UIKit
import Core

class TabBarCoordinator: MainCoordinator {
    
    var navigationController: UINavigationController
    private var selectedTabIndex: Int = 0
    
    init(navigationController: UINavigationController, selectedTab: Int = 0) {
        self.navigationController = navigationController
        self.selectedTabIndex = selectedTab
    }
    
    func start() {
        let tabBarViewController = TabBarController()
        if let window = (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.window {
            window.rootViewController = tabBarViewController
        }
    }
    
    func startWithTab(_ tabIndex: Int) {
        selectedTabIndex = tabIndex
        start()
    }
}
