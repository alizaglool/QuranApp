//
//  AdhkarCoordinator.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 2026-05-23.
//

import UIKit
import Core
import SwiftUI

protocol AdhkarCoordinating: AnyObject {
    func coordinateToAdhkarReading(category: DhikrCategory)
    func coordinateToAllahNames(names: [AllahName])
    func coordinateToAllahNameDetail(names: [AllahName], startIndex: Int)
    func coordinateToMyAdhkar()
    func coordinateBack()
}

class AdhkarCoordinator: MainCoordinator, AdhkarCoordinating {

    var navigationController: UINavigationController
    var tabBarController: TabBarController

    init(navigationController: UINavigationController, tabBarController: TabBarController) {
        self.navigationController = navigationController
        self.tabBarController = tabBarController
    }

    func start() {
        let view = AdhkarCategoriesView(coordinator: self)
        coordinateToView(view)
    }

    func coordinateToAdhkarReading(category: DhikrCategory) {
        let manager = LocalizationManager.shared
        let vc: UIViewController

        switch category.id {
        case "tasbih_extra":
            vc = UIHostingController(rootView:
                TasbihCounterView(coordinator: self, category: category)
                    .environmentObject(manager)
                    .environment(\.layoutDirection, manager.currentLanguage.direction)
            )
        case "loved_ones":
            vc = UIHostingController(rootView:
                LovedOnesDhikrView(coordinator: self, category: category)
                    .environmentObject(manager)
                    .environment(\.layoutDirection, manager.currentLanguage.direction)
            )
        default:
            vc = UIHostingController(rootView:
                AdhkarReadingView(coordinator: self, category: category)
                    .environmentObject(manager)
                    .environment(\.layoutDirection, manager.currentLanguage.direction)
            )
        }

        vc.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(vc, animated: true)
    }

    func coordinateToAllahNames(names: [AllahName]) {
        let manager = LocalizationManager.shared
        let view = AllahNamesView(coordinator: self, names: names)
            .environmentObject(manager)
            .environment(\.layoutDirection, manager.currentLanguage.direction)
        let vc = UIHostingController(rootView: view)
        vc.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(vc, animated: true)
    }

    func coordinateToAllahNameDetail(names: [AllahName], startIndex: Int) {
        let manager = LocalizationManager.shared
        let view = AllahNameReadingView(coordinator: self, names: names, startIndex: startIndex)
            .environmentObject(manager)
            .environment(\.layoutDirection, manager.currentLanguage.direction)
        let vc = UIHostingController(rootView: view)
        vc.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(vc, animated: true)
    }

    func coordinateToMyAdhkar() {
        let manager = LocalizationManager.shared
        let view = MyAdhkarView(coordinator: self)
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
