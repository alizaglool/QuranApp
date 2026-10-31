//
//  ContentCoordinator.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import UIKit
import Core
import SwiftUI

// MARK: - ContentCoordinating

protocol ContentCoordinating: AnyObject {
    func coordinateToGuide(_ key: GuideKey)
    func coordinateBack()
}

// MARK: - ContentCoordinator

class ContentCoordinator: MainCoordinator, ContentCoordinating {

    var navigationController: UINavigationController
    var tabBarController: TabBarController

    init(navigationController: UINavigationController, tabBarController: TabBarController) {
        self.navigationController = navigationController
        self.tabBarController = tabBarController
    }

    func start() {
        push(ContentHubView(coordinator: self))
    }

    func coordinateToGuide(_ key: GuideKey) {
        push(GuideDetailView(key: key, coordinator: self))
    }

    func coordinateBack() {
        navigationController.popViewController(animated: true)
    }

    // MARK: - Presentation

    private func push(_ view: some View) {
        let localizationManager = LocalizationManager.shared
        let hosted = view
            .environmentObject(localizationManager)
            .environment(\.layoutDirection, localizationManager.currentLanguage.direction)
        let viewController = UIHostingController(rootView: hosted)
        viewController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(viewController, animated: true)
    }
}
