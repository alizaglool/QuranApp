//
//  UIApplication+SettingsDialog.swift
//
//
//  Created by Ali M. Zaghloul on 7/6/24.
//

import UIKit

extension UIApplication {
    
    func showGoToSettingsDialog(title: String? = nil, subtitle: String? = nil) {
        topViewController()?.showGoToSettingsDialog(title: title, subtitle: subtitle)
    }
}

public func showGoToSettingsDialog(title: String? = nil, subtitle: String? = nil) {
    UIApplication.shared.showGoToSettingsDialog(title: title, subtitle: subtitle)
}
