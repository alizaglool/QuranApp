//
//  PrayerTimesCoordinator.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 20/10/2026.
//

import UIKit
import Core
import SwiftUI

protocol PrayerTimesCoordinating: AnyObject {
    func coordinateToLocationPicker()
    func coordinateBack()
}

class PrayerTimesCoordinator: MainCoordinator, PrayerTimesCoordinating {

    var navigationController: UINavigationController
    var tabBarController: TabBarController

    init(navigationController: UINavigationController, tabBarController: TabBarController) {
        self.navigationController = navigationController
        self.tabBarController = tabBarController
    }

    func start() {
        push(PrayerTimesView(coordinator: self))
    }

    func coordinateToLocationPicker() {
        push(LocationPickerView(coordinator: self))
    }

    func coordinateBack() {
        navigationController.popViewController(animated: true)
    }
}

// MARK: - Navigation

private extension PrayerTimesCoordinator {

    func push(_ view: some View) {
        let localizationManager = LocalizationManager.shared
        let localizedView = view
            .environmentObject(localizationManager)
            .environment(\.layoutDirection, localizationManager.currentLanguage.direction)

        let viewController = UIHostingController(rootView: localizedView)
        viewController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(viewController, animated: true)
    }
}
