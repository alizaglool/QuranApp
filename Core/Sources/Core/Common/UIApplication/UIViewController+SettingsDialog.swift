//
//  UIViewController+SettingsDialog.swift
//
//
//  Created by Ali M. Zaghloul on 7/6/24.
//

import UIKit

extension UIViewController {
    
    func showGoToSettingsDialog(title: String? = nil, subtitle: String? = nil) {
        
        let alert = UIAlertController(title: title, message: subtitle, preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: "BasicStrings.settings.localized",
                                           style: .default,
                                           handler: {[weak self] _ in
            self?.goToSettings()
        })
        
        let cancelAction = UIAlertAction(title: "BasicStrings.cancel.localized",
                                         style: .cancel,
                                         handler: nil)
        
        alert.addAction(settingsAction)
        alert.addAction(cancelAction)
        
        alert.preferredAction = settingsAction
        
        present(alert, animated: true, completion: nil)
    }
    
    func goToSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

public func goToSettings() {
    if let url = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(url)
    }
}
