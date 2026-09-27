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
    func coordinateToPlaylistItems(playlist: LessonPlaylist, sheikhName: String)
    func coordinateToPlayer(
        source: LessonPlayerViewModel.PlayerSource,
        title: String,
        sheikhName: String,
        playerType: LessonPlayerViewModel.PlayerType,
        relatedVideos: [LessonVideo]
    )
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

    func coordinateToPlaylistItems(playlist: LessonPlaylist, sheikhName: String) {
        let view = PlaylistItemsView(playlist: playlist, sheikhName: sheikhName, coordinator: self)
        let vc = UIHostingController(
            rootView: view
                .environmentObject(LocalizationManager.shared)
                .environment(\.layoutDirection, LocalizationManager.shared.currentLanguage.direction)
        )
        vc.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(vc, animated: true)
    }

    func coordinateToPlayer(
        source: LessonPlayerViewModel.PlayerSource,
        title: String,
        sheikhName: String,
        playerType: LessonPlayerViewModel.PlayerType = .regular,
        relatedVideos: [LessonVideo] = []
    ) {
        let view = LessonPlayerView(
            source: source,
            title: title,
            sheikhName: sheikhName,
            playerType: playerType,
            relatedVideos: relatedVideos
        )
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
