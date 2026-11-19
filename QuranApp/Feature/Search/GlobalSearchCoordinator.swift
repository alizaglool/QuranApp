//
//  GlobalSearchCoordinator.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import Foundation
import UIKit
import SwiftUI
import Core

protocol GlobalSearchCoordinating: AnyObject {
    func coordinateToQuran(target: GlobalSearchQuranTarget)
    func coordinateToNarration(hadiths: [HadithEntry],
                               startIndex: Int,
                               book: HadithBook,
                               chapter: HadithChapter,
                               chapters: [HadithChapter],
                               highlight: HadithSearchQuery?)
    func coordinateToDhikr(packKey: String, itemID: Int)
    func coordinateBack()
}

class GlobalSearchCoordinator: MainCoordinator, GlobalSearchCoordinating {

    var navigationController: UINavigationController
    var tabBarController: TabBarController

    private let onOpenQuran: (GlobalSearchQuranTarget) -> Void
    private let manifestService: AthkarManifestService
    private let packStore: AthkarPackStore

    private lazy var hadithCoordinator = HadithCoordinator(navigationController: navigationController,
                                                           tabBarController: tabBarController)

    private lazy var adhkarCoordinator = AdhkarCoordinator(navigationController: navigationController,
                                                           tabBarController: tabBarController)

    init(navigationController: UINavigationController,
         tabBarController: TabBarController,
         manifestService: AthkarManifestService = .shared,
         packStore: AthkarPackStore = .shared,
         onOpenQuran: @escaping (GlobalSearchQuranTarget) -> Void) {
        self.navigationController = navigationController
        self.tabBarController = tabBarController
        self.manifestService = manifestService
        self.packStore = packStore
        self.onOpenQuran = onOpenQuran
    }

    func start() {
        let localizationManager = LocalizationManager.shared
        let view = GlobalSearchView(coordinator: self)
            .environmentObject(localizationManager)
            .environment(\.layoutDirection, localizationManager.currentLanguage.direction)
        let viewController = UIHostingController(rootView: view)
        viewController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(viewController, animated: true)
    }

    func coordinateToQuran(target: GlobalSearchQuranTarget) {
        onOpenQuran(target)
    }

    func coordinateToNarration(hadiths: [HadithEntry],
                               startIndex: Int,
                               book: HadithBook,
                               chapter: HadithChapter,
                               chapters: [HadithChapter],
                               highlight: HadithSearchQuery?) {
        hadithCoordinator.coordinateToReading(hadiths: hadiths,
                                              startIndex: startIndex,
                                              book: book,
                                              chapter: chapter,
                                              chapters: chapters,
                                              highlight: highlight)
    }

    func coordinateToDhikr(packKey: String, itemID: Int) {
        guard let pack = manifestService.pack(key: packKey) else { return }
        let items = packStore.items(forKey: packKey)
        guard !items.isEmpty else { return }
        adhkarCoordinator.coordinateToAthkarReader(pack: pack, items: items, startItemID: itemID)
    }

    func coordinateBack() {
        navigationController.popViewController(animated: true)
    }
}
