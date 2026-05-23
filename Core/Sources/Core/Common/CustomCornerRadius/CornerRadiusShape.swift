//
//  CornerRadiusShape.swift
//  
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import SwiftUI

struct CornerRadiusShape: Shape {
    
    var radius = CGFloat.infinity
    var corners = UIRectCorner.allCorners
    
    func path(in rect: CGRect) -> Path {
        
        let path = UIBezierPath(roundedRect: rect,
                                byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        
        return Path(path.cgPath)
    }
}
