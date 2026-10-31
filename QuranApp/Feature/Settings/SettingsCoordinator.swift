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
    func coordinateToQuranPacks()
    func coordinateToWorshipTracker()
    func coordinateToStorage()
    func coordinateToPrayerNotifications()
}

class SettingsCoordinator: MainCoordinator, SettingsCoordinating {

    var navigationController: UINavigationController
    var tabBarController: TabBarController

    private lazy var storageCoordinator = StorageCoordinator(
        navigationController: navigationController,
        tabBarController: tabBarController
    )

    private lazy var prayerNotificationSettingsCoordinator = PrayerNotificationSettingsCoordinator(
        navigationController: navigationController,
        tabBarController: tabBarController
    )

    private lazy var quranPackDownloadsCoordinator = QuranPackDownloadsCoordinator(
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

    func coordinateToPrayerNotifications() {
        prayerNotificationSettingsCoordinator.start()
    }

    func coordinateToQuranPacks() {
        quranPackDownloadsCoordinator.start()
    }
}

// MARK: - Prayer Notification Settings Coordinator

protocol PrayerNotificationSettingsCoordinating: AnyObject {
    func coordinateBack()
}

class PrayerNotificationSettingsCoordinator: MainCoordinator, PrayerNotificationSettingsCoordinating {

    var navigationController: UINavigationController
    var tabBarController: TabBarController

    init(navigationController: UINavigationController, tabBarController: TabBarController) {
        self.navigationController = navigationController
        self.tabBarController = tabBarController
    }

    func start() {
        let localizationManager = LocalizationManager.shared
        let view = PrayerNotificationSettingsView(coordinator: self)
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
