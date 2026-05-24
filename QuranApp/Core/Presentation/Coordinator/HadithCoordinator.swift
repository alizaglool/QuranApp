//
//  HadithCoordinator.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 2026-05-23.
//

import UIKit
import Core
import SwiftUI

protocol HadithCoordinating: AnyObject {
    func coordinateToHadithReading(collection: HadithCollection)
    func coordinateBack()
}

class HadithCoordinator: MainCoordinator, HadithCoordinating {

    var navigationController: UINavigationController
    var tabBarController: TabBarController

    init(navigationController: UINavigationController, tabBarController: TabBarController) {
        self.navigationController = navigationController
        self.tabBarController = tabBarController
    }

    func start() {
        let view = HadithLibraryView(coordinator: self)
        coordinateToView(view)
    }

    func coordinateToHadithReading(collection: HadithCollection) {
        let manager = LocalizationManager.shared
        let view = HadithReadingView(coordinator: self, collection: collection)
            .environmentObject(manager)
            .environment(\.layoutDirection, manager.currentLanguage.direction)
        let vc = UIHostingController(rootView: view)
        vc.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(vc, animated: true)
    }

    func coordinateBack() {
        navigationController.popViewController(animated: true)
    }
}
