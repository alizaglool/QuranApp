//
//  WorshipCoordinator.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 18/10/2026.
//

import UIKit
import Core
import SwiftUI

protocol WorshipCoordinating: AnyObject {
    func coordinateBack()
}

class WorshipCoordinator: MainCoordinator, WorshipCoordinating {

    var navigationController: UINavigationController
    var tabBarController: TabBarController

    init(navigationController: UINavigationController, tabBarController: TabBarController) {
        self.navigationController = navigationController
        self.tabBarController = tabBarController
    }

    func start() {
        let localizationManager = LocalizationManager.shared
        let view = WorshipTrackerView(coordinator: self)
            .environmentObject(localizationManager)
            .environment(\.layoutDirection, localizationManager.currentLanguage.direction)
        let viewController = UIHostingController(rootView: view)
        viewController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(viewController, animated: true)
    }

    func coordinateBack() {
        navigationController.popViewController(animated: true)
    }
}
