//
//  LessonsCoordinator.swift
//  QuranApp
//

import UIKit
import SwiftUI
import Core

// MARK: - Protocol

protocol LessonsCoordinating: AnyObject {
    func coordinateToSheikhDetail(sheikh: Sheikh)
    func coordinateToPlayer(source: LessonPlayerViewModel.PlayerSource, title: String, sheikhName: String)
    func coordinateBack()
}

// MARK: - Implementation

final class LessonsCoordinator: MainCoordinator, LessonsCoordinating {

    var navigationController: UINavigationController
    weak var tabBarController: UITabBarController?

    init(navigationController: UINavigationController, tabBarController: UITabBarController?) {
        self.navigationController = navigationController
        self.tabBarController = tabBarController
    }

    func start() {}

    func coordinateToSheikhDetail(sheikh: Sheikh) {
        let view = SheikhDetailView(sheikh: sheikh, coordinator: self)
        let vc = UIHostingController(
            rootView: view
                .environmentObject(LocalizationManager.shared)
                .environment(\.layoutDirection, LocalizationManager.shared.currentLanguage.direction)
        )
        vc.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(vc, animated: true)
    }

    func coordinateToPlayer(source: LessonPlayerViewModel.PlayerSource, title: String, sheikhName: String) {
        let view = LessonPlayerView(source: source, title: title, sheikhName: sheikhName)
        let vc = UIHostingController(
            rootView: view
                .environmentObject(LocalizationManager.shared)
                .environment(\.layoutDirection, LocalizationManager.shared.currentLanguage.direction)
        )
        vc.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(vc, animated: true)
    }

    func coordinateBack() {
        navigationController.popViewController(animated: true)
    }
}
