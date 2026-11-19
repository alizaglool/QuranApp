//
//  InsightsCoordinator.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import UIKit
import SwiftUI
import Core

protocol InsightsCoordinating: AnyObject {
    func coordinateBack()
}

class InsightsCoordinator: MainCoordinator, InsightsCoordinating {

    var navigationController: UINavigationController
    var tabBarController: TabBarController

    init(navigationController: UINavigationController, tabBarController: TabBarController) {
        self.navigationController = navigationController
        self.tabBarController = tabBarController
    }

    func start() {
        let localizationManager = LocalizationManager.shared
        let view = InsightsView(coordinator: self)
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
