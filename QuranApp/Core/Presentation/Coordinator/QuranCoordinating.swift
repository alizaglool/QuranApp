//
//  QuranCoordinating.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 2026-03-26.
//


import Foundation
import UIKit
import Core
import SwiftUI

protocol QuranCoordinating: AnyObject {
    func dismiss()
}

class QuranCoordinator: MainCoordinator, QuranCoordinating {
    
    var navigationController: UINavigationController
    var tabBarController: TabBarController
    
    init(navigationController: UINavigationController, tabBarController: TabBarController) {
        self.navigationController = navigationController
        self.tabBarController = tabBarController
    }
    
    func start() { }
    
    func start(page: Int = 1) {
        let view = QuranPagerView()
        let viewController = UIHostingController(
            rootView: view
                .environmentObject(LocalizationManager.shared)
                .environment(\.layoutDirection, .rightToLeft)
        )
        viewController.modalPresentationStyle = .fullScreen
        navigationController.setViewControllers([viewController], animated: false)
        navigationController.isNavigationBarHidden = true
    }
    
    func dismiss() {
        navigationController.popViewController(animated: true)
    }
}
