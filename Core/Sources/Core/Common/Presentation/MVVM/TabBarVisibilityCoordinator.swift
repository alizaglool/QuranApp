//
//  TabBarVisibilityCoordinator.swift
//
//
//  Created by Ali Zaghloul on 20/10/2026.
//

import Foundation

public final class TabBarVisibilityCoordinator {

    public static let shared = TabBarVisibilityCoordinator()

    private var screensRequestingHiddenTabBar: Int = 0

    private init() {}
}

// MARK: - Visibility Requests

public extension TabBarVisibilityCoordinator {

    func requestHiddenTabBar() {
        screensRequestingHiddenTabBar += 1
        hideTabBar()
    }

    func withdrawHiddenTabBarRequest() {
        screensRequestingHiddenTabBar = max(0, screensRequestingHiddenTabBar - 1)
        guard screensRequestingHiddenTabBar == 0 else { return }
        showTabBar()
    }

    func requestVisibleTabBar() {
        screensRequestingHiddenTabBar = 0
        showTabBar()
    }
}
