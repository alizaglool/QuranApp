//
//  FontStyle.swift
//
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import UIKit

public enum FontStyle: CaseIterable {
    
    case largeTitle
    case heading1
    case heading2
    case heading3
    case headline
    case buttonText
    case subheadline
    case bodyMedium
    case bodySmall
    case caption1
    case caption2
    
    var customFont: CustomFont {
        switch self {
            
        case .largeTitle:
            return .largeTitle
        case .heading1:
            return .heading1
        case .heading2:
            return .heading2
        case .heading3:
            return .heading3
        case .headline:
            return .headline
        case .buttonText:
            return .buttonText
        case .subheadline:
            return .subheadline
        case .bodyMedium:
            return .bodyMedium
        case .bodySmall:
            return .bodySmall
        case .caption1:
            return .caption1
        case .caption2:
            return .caption2
        }
    }
}
