//
//  View+CustomScrolling.swift
//
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import SwiftUI

public extension View {
    
    func customViewAlignedBehavior() -> some View {
        if #available(iOS 17.0, *) {
            return self.scrollTargetBehavior(.viewAligned)
        } else {
            return self
        }
    }
    
    func customScrollTargetLayout() -> some View {
        
        if #available(iOS 17.0, *) {
            return self.scrollTargetLayout()
        } else {
            return self
        }
    }
    
    func customContainerRelativeFrame(width: CGFloat) -> some View {
        
        if #available(iOS 17.0, *) {
            return self.containerRelativeFrame(.horizontal)
        } else {
            return self.frame(width: width)
        }
    }
}
