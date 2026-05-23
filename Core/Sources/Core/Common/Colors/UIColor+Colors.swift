//
//  UIColor+Colors.swift
//  
//
//  Created by Mustafa Merza on 7/7/24.
//

import UIKit

public extension UIColor {
    
    static let primaryColor = UIColor(resource: .primary)
    
    static let toastPrimaryColor = primaryColor
}

// Common core colors
public extension UIColor {
    
    static let tabBarItemUnselected = UIColor(resource: .onSurfaceVariant).withAlphaComponent(0.5)
    
    static let warning = UIColor(resource: .warning)
    
    static let error = UIColor(resource: .error)
    
    static let tabBarBackground = UIColor(resource: .background)
    
    static let shimmerBase = UIColor(resource: .background)
    
    static let shimmerHighlight = UIColor(resource: .secondaryLight)
}
