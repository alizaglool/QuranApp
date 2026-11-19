//
//  HijriCalendarCoordinator.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import Foundation
import UIKit
import SwiftUI
import Core

protocol HijriCalendarCoordinating: AnyObject {
    func coordinateBack()
}

class HijriCalendarCoordinator: MainCoordinator, HijriCalendarCoordinating {

    var navigationController: UINavigationController
    var tabBarController: TabBarController

    init(navigationController: UINavigationController, tabBarController: TabBarController) {
        self.navigationController = navigationController
        self.tabBarController = tabBarController
    }

    func start() {
        let localizationManager = LocalizationManager.shared
        let view = HijriCalendarView(coordinator: self)
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
