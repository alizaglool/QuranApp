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
    func coordinateToRadio()
    func coordinateToRecitations()
    func coordinateToReciterSurahs(reciter: ReciterInfo)
    func coordinateToSheikhDetail(sheikh: Sheikh)
    func coordinateToWorship()
    func coordinateToPrayerTimes()
    func coordinateToLiveStream(station: RadioStation, title: String)
    func coordinateToEgyptianRadio()
    func coordinateToKhatmah()
    func coordinateToContent()
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

    private lazy var adhkarCoordinator = AdhkarCoordinator(
        navigationController: navigationController,
        tabBarController: tabBarController
    )

    private lazy var recitationsCoordinator = RecitationsCoordinator(
        navigationController: navigationController,
        tabBarController: tabBarController
    )

    private lazy var worshipCoordinator = WorshipCoordinator(
        navigationController: navigationController,
        tabBarController: tabBarController
    )

    private lazy var prayerTimesCoordinator = PrayerTimesCoordinator(
        navigationController: navigationController,
        tabBarController: tabBarController
    )

    private lazy var radioCoordinator = RadioCoordinator(
        navigationController: navigationController,
        tabBarController: tabBarController
    )

    private lazy var khatmahCoordinator = KhatmahCoordinator(
        navigationController: navigationController,
        tabBarController: tabBarController,
        onReadPage: { [weak self] page in
            self?.pushQuranPager(startPage: page, openSearchOnAppear: false)
        }
    )

    private lazy var contentCoordinator = ContentCoordinator(
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
        pushQuranPager(startPage: nil, openSearchOnAppear: true)
    }
    
    func coordinateToAdhkar() {
        adhkarCoordinator.start()
    }

    func coordinateToHadith() {
        tabBarController.selectedTabItem = TabBarItem.hadith
    }

    func coordinateToLessons() {
        tabBarController.selectedTabItem = TabBarItem.lessons
    }

    func coordinateToRadio() {
        tabBarController.selectedTabItem = TabBarItem.radio
    }

    func coordinateToRecitations() {
        recitationsCoordinator.start()
    }

    func coordinateToReciterSurahs(reciter: ReciterInfo) {
        recitationsCoordinator.coordinateToReciterSurahs(reciter: reciter)
    }

    func coordinateToSheikhDetail(sheikh: Sheikh) {
        lessonsCoordinator.coordinateToSheikhDetail(sheikh: sheikh)
    }

    func coordinateToWorship() {
        worshipCoordinator.start()
    }

    func coordinateToPrayerTimes() {
        prayerTimesCoordinator.start()
    }

    func coordinateToLiveStream(station: RadioStation, title: String) {
        radioCoordinator.coordinateToLiveChannel(station, title: title)
    }

    func coordinateToEgyptianRadio() {
        radioCoordinator.coordinateToEgyptianRadio()
    }

    func coordinateToKhatmah() {
        khatmahCoordinator.start()
    }

    func coordinateToContent() {
        contentCoordinator.start()
    }

    func coordinateToQuran(startPage: Int? = nil) {
        pushQuranPager(startPage: startPage, openSearchOnAppear: false)
    }

    private func pushQuranPager(startPage: Int?, openSearchOnAppear: Bool) {
        let nav = navigationController
        let view = QuranPagerView(
            startPage: startPage,
            openSearchOnAppear: openSearchOnAppear,
            onBack: { [weak nav] in
                nav?.popViewController(animated: true)
            }
        )
        let viewController = UIHostingController(
            rootView: view
                .environmentObject(LocalizationManager.shared)
                .environment(\.layoutDirection, .rightToLeft)
        )
        viewController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(viewController, animated: true)
    }
}
