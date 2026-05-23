//
//  Image+Images.swift
//  
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import SwiftUI

// Common core images
public extension Image {
    
    static let uiUnderConstruction = Image(.uiUnderConstructionImg)
    static let failure = Image(.failureImg)
    
    static let search = Image(.searchIc)
    
    static let check = Image(.checkIc)
    
    static let eye = Image(.eyeIc)
    static let eyeSlash = Image(.eyeSlashIc)
    
    static let star = Image(.star)
    static let starHalfFilled = Image(.starHalfFilled)
    static let placeholder = Image(.placeholderImg)
    static let backArrow = Image(.backArrow)
}

// App images
public extension Image {
    
    static let noData = Image("no-data-img")
    static let contentPlaceholder = Image("content-placeholder-img")
}

// System images
public extension Image {
    
    static let chevronForward = Image(systemName: "chevron.forward")
    
    static let chevronBackward = Image(systemName: "chevron.backward")
    
    static let chevronUp = Image(systemName: "chevron.up")
    static let chevronDown = Image(systemName: "chevron.down")
    
    static let chevronNext = chevronForward
    static let chevronPrevious = chevronBackward
    
    static let arrowDownFilled = Image(systemName: "arrowtriangle.down.fill")
    
    static let exclamationCircledMark = Image(systemName: "exclamationmark.circle")
    
    static let xMark = Image(systemName: "xmark")
    static let xMarkCircleFilled = Image(systemName: "xmark.circle.fill")
    
    static let questionMark = Image(systemName: "questionmark")
    
    static let rectangleRecord = Image(systemName: "rectangle.dashed.badge.record")
    
    static let lockiPhone = Image(systemName: "lock.iphone")
}
