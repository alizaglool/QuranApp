//
//  StatusBarStyleControllers.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 14/10/2026.
//

import SwiftUI
import UIKit

// MARK: - StatusBarStyleNavigationController

final class StatusBarStyleNavigationController: UINavigationController {

    override var childForStatusBarStyle: UIViewController? {
        topViewController
    }
}

// MARK: - LightStatusBarHostingController

final class LightStatusBarHostingController<Content: View>: UIHostingController<Content> {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
}
