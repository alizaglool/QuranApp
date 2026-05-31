//
//  TabBarController.swift
//  EMLE Learners
//
//  Created by Ali M. Zaghloul on 02/04/2024.
//


import Foundation
import SwiftUI
import Core

class TabBarController: UITabBarController, TabBarControllerProtocol {
    
    var tabBarItems: [TabBarItem] = []
    
    var selectedTabItem: TabBarItem? {
        didSet {
            if let selectedTabItem {
                selectedIndex = tabBarItems.firstIndex(of: selectedTabItem) ?? 0
            } else {
                selectedIndex = 0
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBarItems()
        configure()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configureTitles()
    }
    
    func selectTab(at index: Int) {
        guard index < tabBarItems.count else { return }
        selectedIndex = index
        selectedTabItem = tabBarItems[index]
    }
}


// MARK: - Tab Bar Setup

extension TabBarController {
    
    private func setupTabBarItems() {
        let home = TabBarItem(
            title: AppLocalizedKeys.home.value,
            image: UIImage(systemName: "house.fill")!.withRenderingMode(.alwaysTemplate),
            viewControllerProvider: getHomeViewController
        )
        TabBarItem.home = home
        
        let quran = TabBarItem(
            title: AppLocalizedKeys.quran.value,
            image: UIImage(systemName: "book.fill")!.withRenderingMode(.alwaysTemplate),
            viewControllerProvider: getQuranViewController
        )
        TabBarItem.quran = quran
        
        let adhkar = TabBarItem(
            title: AppLocalizedKeys.adhkar.value,
            image: UIImage(systemName: "sparkles")!.withRenderingMode(.alwaysTemplate),
            viewControllerProvider: getAdhkarViewController
        )
        TabBarItem.adhkar = adhkar
        
        let hadith = TabBarItem(
            title: AppLocalizedKeys.hadith.value,
            image: UIImage(systemName: "text.book.closed.fill")!.withRenderingMode(.alwaysTemplate),
            viewControllerProvider: getHadithViewController
        )
        TabBarItem.hadith = hadith
        
        let lessons = TabBarItem(
            title: AppLocalizedKeys.lessons.value,
            image: UIImage(systemName: "play.rectangle.fill")!.withRenderingMode(.alwaysTemplate),
            viewControllerProvider: getLessonsViewController
        )
        TabBarItem.lessons = lessons

        tabBarItems = [home, quran, adhkar, hadith, lessons]
    }
}

// MARK: - View Controller Providers

extension TabBarController {
    
    private func getHomeViewController() -> UIViewController {
        let navigationController = UINavigationController()
        let coordinator = HomeCoordinator(
            navigationController: navigationController,
            tabBarController: self
        )
        let view = HomeView(coordinator: coordinator)
        let viewController = UIHostingController(
            rootView: view
                .environmentObject(LocalizationManager.shared)
                .environment(\.layoutDirection, LocalizationManager.shared.currentLanguage.direction)
        )
        navigationController.setViewControllers([viewController], animated: false)
        navigationController.isNavigationBarHidden = true
        return navigationController
    }
    
    private func getQuranViewController() -> UIViewController {
        let navigationController = UINavigationController()
        let view = QuranPagerView()
        let viewController = UIHostingController(
            rootView: view
                .environmentObject(LocalizationManager.shared)
                .environment(\.layoutDirection, .rightToLeft)
        )
        navigationController.setViewControllers([viewController], animated: false)
        navigationController.isNavigationBarHidden = true
        return navigationController
    }

    private func getAdhkarViewController() -> UIViewController {
        let navigationController = UINavigationController()
        let coordinator = AdhkarCoordinator(
            navigationController: navigationController,
            tabBarController: self
        )
        let view = AdhkarCategoriesView(coordinator: coordinator)
        let viewController = UIHostingController(
            rootView: view
                .environmentObject(LocalizationManager.shared)
                .environment(\.layoutDirection, LocalizationManager.shared.currentLanguage.direction)
        )
        navigationController.setViewControllers([viewController], animated: false)
        navigationController.isNavigationBarHidden = true
        return navigationController
    }

    private func getHadithViewController() -> UIViewController {
        let navigationController = UINavigationController()
        let coordinator = HadithCoordinator(
            navigationController: navigationController,
            tabBarController: self
        )
        let view = HadithLibraryView(coordinator: coordinator)
        let viewController = UIHostingController(
            rootView: view
                .environmentObject(LocalizationManager.shared)
                .environment(\.layoutDirection, LocalizationManager.shared.currentLanguage.direction)
        )
        navigationController.setViewControllers([viewController], animated: false)
        navigationController.isNavigationBarHidden = true
        return navigationController
    }

    private func getLessonsViewController() -> UIViewController {
        // TODO: Lessons
        return UIViewController()
    }
}
