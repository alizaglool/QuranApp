//
//  RecitationsCoordinator.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 12/10/2026
//

import UIKit
import Core
import SwiftUI

protocol RecitationsCoordinating: AnyObject {
    func coordinateToReciterSurahs(reciter: ReciterInfo)
    func coordinateBack()
}

class RecitationsCoordinator: MainCoordinator, RecitationsCoordinating {

    var navigationController: UINavigationController
    var tabBarController: TabBarController

    init(navigationController: UINavigationController, tabBarController: TabBarController) {
        self.navigationController = navigationController
        self.tabBarController = tabBarController
    }

    func start() {
        let view = RecitersListView(coordinator: self)
        coordinateToView(view)
    }

    func coordinateToReciterSurahs(reciter: ReciterInfo) {
        let view = ReciterSurahsView(coordinator: self, reciter: reciter)
        coordinateToView(view)
    }
}
