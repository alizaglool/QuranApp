//
//  OptionalAnimation.swift
//  Core
//
//  Created by Ali M. Zaghloul on 03/06/2025.
//


import Foundation
import SwiftUI

public func withOptionalAnimation<Result>(_ animation: Animation? = .default, _ body: () throws -> Result) rethrows -> Result {
    
    if UIAccessibility.isReduceMotionEnabled {
        return try body()
    }
    else {
        return try withAnimation(animation, body)
    }
}
