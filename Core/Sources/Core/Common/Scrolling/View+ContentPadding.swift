//
//  View+ContentPadding.swift
//
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import SwiftUI

public extension View {
    
    func customContentPadding(_ edges: Edge.Set = .all,
                              _ length: CGFloat? = nil) -> some View {
        
        if #available(iOS 17.0, *) {
            return self
        } else {
            return self.padding(edges, length)
        }
    }
}
