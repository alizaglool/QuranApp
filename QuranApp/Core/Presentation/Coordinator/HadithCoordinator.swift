//
//  HadithCoordinator.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 2026-05-25.
//

import UIKit
import Core
import SwiftUI

protocol HadithCoordinating: AnyObject {
    func coordinateToChapters(book: HadithBook)
    func coordinateToReading(hadiths: [HadithEntry], startIndex: Int, book: HadithBook)
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

    func coordinateToChapters(book: HadithBook) {
        let manager = LocalizationManager.shared
        let view = HadithChaptersView(coordinator: self, book: book)
            .environmentObject(manager)
            .environment(\.layoutDirection, manager.currentLanguage.direction)
        let vc = UIHostingController(rootView: view)
        vc.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(vc, animated: true)
    }

    func coordinateToReading(hadiths: [HadithEntry], startIndex: Int, book: HadithBook) {
        let manager = LocalizationManager.shared
        let view = HadithReadingView(coordinator: self, hadiths: hadiths, startIndex: startIndex, book: book)
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
