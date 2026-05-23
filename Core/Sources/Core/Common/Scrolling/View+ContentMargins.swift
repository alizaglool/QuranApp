//
//  View+ContentMargins.swift
//
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import SwiftUI

public extension View {
    
    func customContentMargins(_ edges: Edge.Set = .all,
                              _ length: CGFloat?) -> some View {
        
        if #available(iOS 17.0, *) {
            return self.contentMargins(edges, length, for: .scrollContent)
        } else {
            return self
        }
    }
}
