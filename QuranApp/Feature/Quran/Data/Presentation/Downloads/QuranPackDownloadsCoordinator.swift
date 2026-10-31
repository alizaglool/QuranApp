//
//  QuranPackDownloadsCoordinator.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 29/10/2026.
//

import Foundation
import UIKit
import SwiftUI
import Core

protocol QuranPackDownloadsCoordinating: AnyObject {
    func coordinateBack()
}

class QuranPackDownloadsCoordinator: MainCoordinator, QuranPackDownloadsCoordinating {

    var navigationController: UINavigationController
    var tabBarController: TabBarController

    init(navigationController: UINavigationController, tabBarController: TabBarController) {
        self.navigationController = navigationController
        self.tabBarController = tabBarController
    }

    func start() {
        let localizationManager = LocalizationManager.shared
        let view = QuranPackDownloadsView(coordinator: self)
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
