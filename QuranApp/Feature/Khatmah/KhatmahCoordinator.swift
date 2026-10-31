//
//  KhatmahCoordinator.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import UIKit
import Core
import SwiftUI

// MARK: - KhatmahCoordinating

protocol KhatmahCoordinating: AnyObject {
    func coordinateToQuranPage(_ page: Int)
    func coordinateBack()
}

// MARK: - KhatmahCoordinator

class KhatmahCoordinator: MainCoordinator, KhatmahCoordinating {

    var navigationController: UINavigationController
    var tabBarController: TabBarController

    private let onReadPage: (Int) -> Void

    init(navigationController: UINavigationController,
         tabBarController: TabBarController,
         onReadPage: @escaping (Int) -> Void) {
        self.navigationController = navigationController
        self.tabBarController = tabBarController
        self.onReadPage = onReadPage
    }

    func start() {
        let localizationManager = LocalizationManager.shared
        let view = KhatmahPlanView(coordinator: self)
            .environmentObject(localizationManager)
            .environment(\.layoutDirection, localizationManager.currentLanguage.direction)
        let viewController = UIHostingController(rootView: view)
        viewController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(viewController, animated: true)
    }

    func coordinateToQuranPage(_ page: Int) {
        onReadPage(page)
    }

    func coordinateBack() {
        navigationController.popViewController(animated: true)
    }
}
