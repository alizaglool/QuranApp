//
//  RadioCoordinator.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 12/10/2026
//

import UIKit
import SwiftUI
import Core

// MARK: - RadioCoordinating

protocol RadioCoordinating: AnyObject {
    func start()
    func coordinateToLiveChannel(_ station: RadioStation, title: String)
    func coordinateToEgyptianRadio()
    func coordinateBack()
}

// MARK: - RadioCoordinator

class RadioCoordinator: MainCoordinator, RadioCoordinating {

    var navigationController: UINavigationController
    var tabBarController: TabBarController

    init(navigationController: UINavigationController, tabBarController: TabBarController) {
        self.navigationController = navigationController
        self.tabBarController = tabBarController
    }

    func start() {
        let view = RadioStationsView(coordinator: self)
        coordinateToView(view)
    }

    func coordinateToLiveChannel(_ station: RadioStation, title: String) {
        let view = LiveChannelPlayerView(station: station, title: title, coordinator: self)
        let viewController = UIHostingController(
            rootView: view
                .environmentObject(LocalizationManager.shared)
                .environment(\.layoutDirection, LocalizationManager.shared.currentLanguage.direction)
        )
        viewController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(viewController, animated: true)
    }

    func coordinateToEgyptianRadio() {
        let view = EgyptianRadioView(coordinator: self)
        let viewController = UIHostingController(
            rootView: view
                .environmentObject(LocalizationManager.shared)
                .environment(\.layoutDirection, LocalizationManager.shared.currentLanguage.direction)
        )
        viewController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(viewController, animated: true)
    }

    func coordinateBack() {
        navigationController.popViewController(animated: true)
    }
}
