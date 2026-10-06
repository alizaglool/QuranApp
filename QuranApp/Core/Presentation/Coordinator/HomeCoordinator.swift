//
//  HomeViewModel.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 2026-03-23.
//

import Foundation
import UIKit
import Core
import SwiftUI

protocol HomeCoordinating: AnyObject {
    func coordinateToSurahDetail(surah: SurahEntity)
    func coordinateToSearch()
    func coordinateToQuran(startPage: Int?)
    func coordinateToAdhkar()
    func coordinateToHadith()
    func coordinateToLessons()
    func coordinateToSheikhDetail(sheikh: Sheikh)
}

class HomeCoordinator: MainCoordinator, HomeCoordinating {
    
    var navigationController: UINavigationController
    var tabBarController: TabBarController

    /// Sheikh detail belongs to the Lessons module and takes a `LessonsCoordinating`,
    /// so Home delegates to a Lessons coordinator driving Home's own nav stack — the
    /// pushed screen stays in the Home tab and Back returns here.
    ///
    /// Stored rather than built per push because `SheikhDetailViewModel.coordinator`
    /// is `weak`: a local instance would deallocate before the first tap inside the
    /// pushed screen, leaving its playlist and player rows dead.
    private lazy var lessonsCoordinator = LessonsCoordinator(
        navigationController: navigationController,
        tabBarController: tabBarController
    )
    
    init(navigationController: UINavigationController, tabBarController: TabBarController) {
        self.navigationController = navigationController
        self.tabBarController = tabBarController
    }
    
    func start() {
        let homeView = HomeView(coordinator: self)
        coordinateToView(homeView)
    }
    
    func coordinateToSurahDetail(surah: SurahEntity) {
        // TODO
    }
    
    func coordinateToSearch() {
        // TODO
    }
    
    func coordinateToAdhkar() {
        tabBarController.selectedTabItem = TabBarItem.adhkar
    }

    func coordinateToHadith() {
        tabBarController.selectedTabItem = TabBarItem.hadith
    }

    func coordinateToLessons() {
        tabBarController.selectedTabItem = TabBarItem.lessons
    }

    func coordinateToSheikhDetail(sheikh: Sheikh) {
        lessonsCoordinator.coordinateToSheikhDetail(sheikh: sheikh)
    }

    func coordinateToQuran(startPage: Int? = nil) {
        let nav = navigationController
        let view = QuranPagerView(startPage: startPage, onBack: { [weak nav] in
            nav?.popViewController(animated: true)
        })
        let viewController = UIHostingController(
            rootView: view
                .environmentObject(LocalizationManager.shared)
                .environment(\.layoutDirection, .rightToLeft)
        )
        viewController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(viewController, animated: true)
    }
}
