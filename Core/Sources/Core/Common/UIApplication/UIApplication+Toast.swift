//
//  UIApplication+Toast.swift
//  
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import UIKit

extension UIApplication {
    
    public static let toastDuration: Double = 4.0
    
    func showToast(title: String? = nil, message: String, with duration: Double = UIApplication.toastDuration) {
        
        var style = ToastStyle()
        style.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        makeToast(message: message, duration: duration, title: title, style: style)
    }
    
    func showErrorToast(title: String? = nil, message: String, with duration: Double = UIApplication.toastDuration) {
        
        var style = ToastStyle()
        style.backgroundColor = .error
        makeToast(message: message, duration: duration, title: title, style: style)
    }
    
    func showSuccessToast(title: String? = nil, message: String, with duration: Double = UIApplication.toastDuration) {
        
        var style = ToastStyle()
        style.backgroundColor = .toastPrimaryColor
        makeToast(message: message, duration: duration, title: title, style: style)
    }
    
    private func makeToast(message: String, duration: Double, title: String?, style: ToastStyle) {
        if let window = (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegateProtocol)?.window {
            
            let position: ToastPosition = isTabBarHidden ? .bottom : .aboveTabBar
            window.makeToast(message, duration: duration, position: position, title: title, image: nil, style: style, completion: nil)
        }
    }
}

public func showToast(title: String? = nil, message: String, with duration: Double = UIApplication.toastDuration) {
    UIApplication.shared.showToast(title: title, message: message, with: duration)
}

public func showErrorToast(title: String? = nil, error: Error, with duration: Double = UIApplication.toastDuration) {
    UIApplication.shared.showErrorToast(title: title, message: "Error\n\(error)", with: duration)
}

public func showErrorToast(title: String? = nil, message: String, with duration: Double = UIApplication.toastDuration) {
    UIApplication.shared.showErrorToast(title: title, message: message, with: duration)
}

public func showSuccessToast(title: String? = nil, message: String, with duration: Double = UIApplication.toastDuration) {
    UIApplication.shared.showSuccessToast(title: title, message: message, with: duration)
}
