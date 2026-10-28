//
//  SettingsCoordinator.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 18/10/2026.
//

import UIKit
import Core
import SwiftUI

protocol SettingsCoordinating: AnyObject {
    func coordinateToWorshipTracker()
    func coordinateToStorage()
}

class SettingsCoordinator: MainCoordinator, SettingsCoordinating {

    var navigationController: UINavigationController
    var tabBarController: TabBarController

    private lazy var storageCoordinator = StorageCoordinator(
        navigationController: navigationController,
        tabBarController: tabBarController
    )

    init(navigationController: UINavigationController, tabBarController: TabBarController) {
        self.navigationController = navigationController
        self.tabBarController = tabBarController
    }

    func start() {
        let localizationManager = LocalizationManager.shared
        let view = SettingsView(coordinator: self)
            .environmentObject(localizationManager)
            .environment(\.layoutDirection, localizationManager.currentLanguage.direction)
        let viewController = UIHostingController(rootView: view)
        navigationController.setViewControllers([viewController], animated: false)
    }

    func coordinateToWorshipTracker() {
        let worshipCoordinator = WorshipCoordinator(
            navigationController: navigationController,
            tabBarController: tabBarController
        )
        coordinate(to: worshipCoordinator)
    }

    func coordinateToStorage() {
        storageCoordinator.start()
    }
}
