//
//  CustomFontWeight.swift
//
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import UIKit

public enum CustomFontWeight: Int {
    
    case _100 = 100
    case _200 = 200
    case _300 = 300
    case _400 = 400
    case _500 = 500
    case _600 = 600
    case _700 = 700
    case _800 = 800
    case _900 = 900
    
    var weight: UIFont.Weight {
        switch self {
        case ._100:
            return .thin
        case ._200:
            return .ultraLight
        case ._300:
            return .light
        case ._400:
            return .regular
        case ._500:
            return .medium
        case ._600:
            return .semibold
        case ._700:
            return .bold
        case ._800:
            return .heavy
        case ._900:
            return .black
        }
    }
    
    var weightName: String {
        switch weight {
            
        case .thin:
            return "Thin"
        case .ultraLight:
            return "ExtraLight"
        case .light:
            return "Light"
        case .regular:
            return "Regular"
        case .medium:
            return "Medium"
        case .semibold:
            return "SemiBold"
        case .bold:
            return "Bold"
        case .heavy:
            return "ExtraBold"
        case .black:
            return "Black"
        default:
            return "Regular"
        }
    }
}
